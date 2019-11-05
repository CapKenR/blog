# Roll Your Own Developer Experience

A recent Red Hat press release, [Red Hat Expands the Kubernetes Developer Experience with Newest Version of Red Hat OpenShift 4](https://www.redhat.com/en/about/press-releases/red-hat-expands-kubernetes-developer-experience-newest-version-red-hat-openshift-4), talks about the new developer services they've included in OpenShift 4.2. In reality, their Service Mesh service is [Istio](https://istio.io), Serverless is [Knative](https://knative.dev/), and Pipelines is [Tekton Pipelines](https://tekton.dev/). In the past, Red Hat has talked about running the machine learning toolkit [KubeFlow](https://www.kubeflow.org/) in OpenShift as well. Over the past year I've had the opportunity to run each of these in test Kubernetes clusters built using [Docker Enterprise](https://www.docker.com/products/docker-enterprise). In this post, I'll show you how to bring them all up in your own cluster.

## Istio for Service Mesh

[Installing Istio](https://istio.io/docs/setup/#installing-istio)

By default, Istio uses a `LoadBalancer` type for its ingress gateway. That works fine if you're in AWS, Azure or GCP but doesn't work for an on-premises cluster and/or clusters in multiple public clouds or you just don't want to be tied to a cloud provider implementation. We also want to control the HTTP and HTTPS ports used by our own load balancer. To accomplish this, we'll create an additional values file for our install that specifies `NodePort` for the type of gateway and the ports we want to use for HTTP and HTTPS. (In this case we're using 35080 and 35443, respecitely.)

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
      targetPort: 443
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

For our case, we're going to use the demo configuration option for the Istio install as it enables most of its functionality with minimal resource requirements. (For a comparison of the various options, see [Installation Configuration Profiles](https://istio.io/docs/setup/additional-setup/config-profiles/).)

```bash
$ kubectl create namespace istio-system
$ helm template istio-init install/kubernetes/helm/istio-init --namespace istio-system | kubectl apply -f -
$ helm template istio install/kubernetes/helm/istio --namespace istio-system --values install/kubernetes/helm/istio/values-istio-demo.yaml --values ./values-docker-enterprise.yaml | kubectl apply -f -
```

## Knative for Serverless

[Install on a Kubernetes cluster](https://knative.dev/docs/install/knative-with-any-k8s/)

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

## Tekton for CI/CD

[Installing Tekton Pipelines](https://github.com/tektoncd/pipeline/blob/master/docs/install.md)

```bash
$ kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

## Kubeflow for Machine Learning

[Kubeflow Deployment with kfctl_k8s_istio](https://www.kubeflow.org/docs/started/k8s/kfctl-k8s-istio/)

## Summary

Products like OpenShift are very perscriptive on how you do your work but you don't have to be. You can use all the same tools in your own Kubernetes cluster without being constrained by how another company thinks you should use them. For example, you may want to use [Linkerd](https://linkerd.io/) instead of Istio for your service mesh or [OpenFaaS](https://www.openfaas.com/) instead of Knative for serverless. One of the big advantages with using Docker Enterprise is the choice and flexibility it provides to build the infrastructure you need. If you want or need help, Capstone IT is a Docker Premier Consulting Partner as well as being an Azure Gold and AWS Select partner. If you are interested in finding out more and getting help with your Container, Cloud and DevOps transformation, please [Contact Us](https://capstonec.com/contact-us/).

Ken Rider
Solutions Architect
Capstone IT