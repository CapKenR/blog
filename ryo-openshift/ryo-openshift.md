# Roll Your Own OpenShift Developer Services

A recent Red Hat press release, [Red Hat Expands the Kubernetes Developer Experience with Newest Version of Red Hat OpenShift 4](https://www.redhat.com/en/about/press-releases/red-hat-expands-kubernetes-developer-experience-newest-version-red-hat-openshift-4), talks about the new developer services they've included in OpenShift 4.2. In reality, their Service Mesh service is [Istio](https://istio.io), Serverless is [Knative](https://knative.dev/), and Pipelines is [Tekton Pipelines](https://tekton.dev/). In the past, Red Hat has talked about running the machine learning toolkit [KubeFlow](https://www.kubeflow.org/) in OpenShift as well. Over the past year I've had the opportunity to run each of these in test Kubernetes clusters built using [Docker Enterprise](https://www.docker.com/products/docker-enterprise). In this post, I'll show you how to bring them all up in your own cluster.

## Istio

```yaml values-docker-enterpise.yaml
gateways:
  istio-ingressgateway:
    type: NodePort
    ports:
    - port: 15020
      targetPort: 15020
      name: status-port
    - port: 80
      targetPort: 80
      name: http2
      nodePort: 35080
    - port: 443
      name: https
      nodePort: 35443
    - port: 15029
      targetPort: 15029
      name: https-kiali
    - port: 15030
      targetPort: 15030
      name: https-prometheus
    - port: 15031
      targetPort: 15031
      name: https-grafana
    - port: 15032
      targetPort: 15032
      name: https-tracing
    - port: 15443
      targetPort: 15443
      name: tls
```

```bash
$ helm template istio install/kubernetes/helm/istio --namespace istio-system --values install/kubernetes/helm/istio/values-istio-demo.yaml --values ./values-docker-enterprise.yaml
```

## Knative

```bash
$ kubectl apply --selector knative.dev/crd-install=true \
   --filename https://github.com/knative/serving/releases/download/v0.10.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.10.0/release.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.10.0/monitoring.yaml
```

```bash
$ kubectl apply \
   --filename https://github.com/knative/serving/releases/download/v0.10.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.10.0/release.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.10.0/monitoring.yaml
```

## Tekton

[Installing Tekton Pipelines](https://github.com/tektoncd/pipeline/blob/master/docs/install.md)

```bash
$ kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```
