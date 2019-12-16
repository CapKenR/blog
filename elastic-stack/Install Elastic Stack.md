# Getting Tomcat logs from Kubernetes pods

I have been working with a client recently on getting Tomcat access and error logs Kubernetes pods. As I started to look at the problem, it also seemed like a good idea to move them up to the latest release. And, now that Helm 3 has been released and no longer requires Tiller, using the [Elastic Stack Kubernetes Helm Charts](https://github.com/elastic/helm-charts#elastic-stack-kubernetes-helm-charts) to manage their installs made a lot of sense.

## Install Helm 3

I recently did a blog post, [A First Look at Helm 3](https://capstonec.com/a-first-look-at-helm-3/), that talks about the latest release. To find out more, read that post (first). Installing helm is easy. Here's how I did it on Ubuntu.

```bash
$ wget https://get.helm.sh/helm-v3.0.1-linux-amd64.tar.gz
$ tar xzf helm-v3.0.1-linux-amd64.tar.gz
$ sudo mv linux-amd64/helm /usr/local/bin/helm
```

## Use the Elastic Helm repository
Elastic has their own Helm repository for their Elasticsearch, Kibana, Filebeat, Metricbeat, and Logstash charts. To use their repository, you need to add it to helm as follows.

```bash
$ helm repo add elastic https://helm.elastic.co
$ helm repo update
```

## Create a namespace for Elastic Stack

```bash
$ kubectl create namespace elastic-system
```

## Install the Elastic Stack

The Elastic Stack typically refers to use of Elasticsearch, Kibana, Filebeat, and Metricbeat in concert. We're not going to use Metricbeat in this example as we already have a Prometheus/Grafana implementation as part of the Istio implementation in our Kubernetes cluster.

### Install Elasticsearch

Elasticsearch is the most popular enterprise search engine in the world. To install it, we'll use helm then monitor the pods created until they are running using the following commands.

```bash
$ helm install -n elastic-system --verion 7.5.0 elasticsearch elastic/elasticsearch
$ kubectl -n elastic-system get pods -l app=elasticsearch-master -w
```

### Install Kibana

Next, we'll install Kibana using helm. Kibana is a visualization tool for data in Elasticsearch. We're going to modify the default values for the chart (slightly) to have Kibana decode JSON in `message` fields to make it easier to read. Here's the content of my `kibana-values.yaml` file.

```yaml
podAnnotations:
  co.elastic.logs/processors.decode_json_fields.fields: message
  co.elastic.logs/processors.decode_json_fields.target: kibana
```

And, here's how we install Kibana using Elastic's chart and our values file. Again, we monitor the created pods until they're running.

```bash
$ helm install -n elastic-system --version 7.5.0 --values kibana-values.yaml kibana elastic/kibana
$ kubectl -n elastic-system get pods -l app=kibana -w
```

### Install Filebeat

Filebeat is a shipper for log files. It's part of the Beats family of shippers from Elastic. Filebeat reads specified log files, processes them, and ships the data to Elasticsearch. As part of its setup, it can create indices in Elasticsearch and/or dashboards in Kibana.

In our case, we're going to enable the Apache module (since that's the format used for Tomcat log files) and we're going to have it create the default dashboards in Kibana. Note: the `kibana-kibana` host name is based on the Kibana service and is derived from the name we gave to the helm install above. The other item of note is we're going to add Kubernetes metadata to the data we send to Elasticsearch from the Docker container logs. Here's the `filebeat-values.yaml` file we'll use.

```yaml
filebeatConfig:
  filebeat.yml: |
    filebeat:
      config:
        modules:
          path: /usr/share/filebeat/modules.d/*.yml
          reload:
            enabled: true
      modules:
      - module: apache
      inputs:
      - type: docker
        containers.ids:
        - '*'
        processors:
        - add_kubernetes_metadata: ~
    output:
      elasticsearch:
        host: '${NODE_NAME}'
        hosts: '${ELASTICSEARCH_HOSTS:elasticsearch-master:9200}'
    setup:
      kibana:
        host: '${KIBANA_HOST:kibana-kibana:5601}'
        protocol: "http"
      dashboards:
        enabled: true
```

Again, we install the Filebeat daemon set using Elastic's chart and our values file. As before, we monitor the created pods until they're running. There should be one Filebeat pod running on each node of our Kubernetes cluster.

```bash
$ helm install -n elastic-system --version 7.5.0 --values filebeat-values.yaml filebeat elastic/filebeat
$ kubectl -n elastic-system get pods -l app=filebeat-filebeat -w
```

### Elastic Stack Installed

```bash
$ helm -n elastic-system ls
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
elasticsearch   elastic-system  1               2019-12-16 17:11:14.108395919 +0000 UTC deployed        elasticsearch-7.5.0     7.5.0
filebeat        elastic-system  1               2019-12-16 17:22:35.961662641 +0000 UTC deployed        filebeat-7.5.0          7.5.0
kibana          elastic-system  1               2019-12-16 17:20:48.314049147 +0000 UTC deployed        kibana-7.5.0            7.5.0
```

Install the Istio Gateway and VirtualService for Kibana. (Optionally, you can install the Gateway in the istio-system namespace.)

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kibana-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
    - hosts:
        - "test-kibana.lab.capstonec.net"
      port:
        name: "http"
        number: 80
        protocol: "HTTP"
    - hosts:
        - "test-kibana.lab.capstonec.net"
      port:
        name: "https"
        number: 443
        protocol: "HTTPS"
      tls:
        mode: "SIMPLE"
        serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
        privateKey: /etc/istio/ingressgateway-certs/tls.key
```

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kibana-virtualservice
spec:
  hosts:
  - "test-kibana.lab.capstonec.net"
  gateways:
  - kibana-gateway
  http:
  - route:
    - destination:
        port:
          number: 5601
        host: kibana-kibana
```

```bash
$ kubectl -n elastic-system apply -f kibana-gateway.yaml
$ kubectl -n elastic-system apply -f kibana-virtualservice.yaml
```

For the Tomcat logs in /usr/local/tomcat/logs I’m planning on using a Filebeat sidecar with the Apache module but haven’t gotten it working yet.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
 labels:
   app: tomcat
   component: filebeat
 name: filebeat-sidecar-config
data:
  filebeat.yml: |
    filebeat:
      config:
        modules:
          path: /usr/share/filebeat/modules.d/*.yml
          reload:
            enabled: true
      modules:
      - module: apache
        access:
          enabled: true
          var.paths:
          - "/usr/local/tomcat/logs/localhost_access_log.*.txt"
        error:
          enabled: true
          var.paths:
          - "/usr/local/tomcat/logs/application.log*"
          - "/usr/local/tomcat/logs/catalina.*.log"
          - "/usr/local/tomcat/logs/host-manager.*.log"
          - "/usr/local/tomcat/logs/localhost.*.log"
          - "/usr/local/tomcat/logs/manager.*.log"
    output:
      elasticsearch:
        host: '${NODE_NAME}'
        hosts: '${ELASTICSEARCH_HOSTS:elasticsearch-master.elastic-system:9200}'
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat
  labels:
    app: tomcat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tomcat
  template:
    metadata:
      labels:
        app: tomcat
    spec:
      containers:
      - name: filebeat-sidecar
        image: docker.elastic.co/beats/filebeat:7.5.0
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: spec.nodeName
        volumeMounts:
        - name: logs-volume
          mountPath: /usr/local/tomcat/logs
        - name: filebeat-config
          mountPath: /usr/share/filebeat/filebeat.yml
          subPath: filebeat.yml
      - name: tomcat
        image: tomcat
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: logs-volume
          mountPath: /usr/local/tomcat/logs
      securityContext:
        fsGroup: 1000
      volumes:
      - name: logs-volume
        emptyDir: {}
      - name: filebeat-config
        configMap:
          name: filebeat-sidecar-config
          items:
            - key: filebeat.yml
              path: filebeat.yml
```

```bash
$ kubectl -n development apply -f filebeat-configmap.yaml
$ kubectl -n development apply -f tomcat-with-filebeat.yaml
```

## Summary

Products like OpenShift are very perscriptive on how you do your work but you don't have to be. You can use all the same tools in your own Kubernetes cluster without being constrained by how another company thinks you should use them. For example, you may want to use [Linkerd](https://linkerd.io/) instead of Istio for your service mesh, [OpenFaaS](https://www.openfaas.com/) instead of Knative for serverless, and/or [Jenkins X](https://jenkins-x.io/) instead of Tekton for CI/CD. Or, maybe you have your own alternative to Kubeflow. One of the big advantages with using Docker Enterprise is the choice and flexibility it provides to build the infrastructure you need. If you want or need help, Capstone IT is a Docker Premier Consulting Partner as well as being an Azure Gold and AWS Select partner. If you are interested in finding out more and getting help with your Container, Cloud and DevOps transformation, please [Contact Us](https://capstonec.com/contact-us/).

[Ken Rider](https://www.linkedin.com/in/kenrider)  
Solutions Architect  
Capstone IT