# Roll Your Own Developer Experience

A recent Red Hat press release, [Red Hat Expands the Kubernetes Developer Experience with Newest Version of Red Hat OpenShift 4](https://www.redhat.com/en/about/press-releases/red-hat-expands-kubernetes-developer-experience-newest-version-red-hat-openshift-4), talks about the new developer services they've included in OpenShift 4.2. However, these services are not confined to OpenShift. In reality, their Service Mesh service is [Istio](https://istio.io), their Serverless service is [Knative](https://knative.dev/), and their Pipelines service is [Tekton Pipelines](https://tekton.dev/). In the past, Red Hat has talked about running the machine learning toolkit [KubeFlow](https://www.kubeflow.org/) in OpenShift as well. Over the past year I've had the opportunity to run each of these services in Kubernetes clusters built using [Docker Enterprise](https://www.docker.com/products/docker-enterprise). In this post, I'll show you how to roll your own developer experience by bringing them all up in your own cluster.

## Istio for Service Mesh

### What is Istio?

As a service mesh implementation, Istio helps to remove the complexity from connecting, securing, controlling, and observing services deployed in a Kubernetes infrastructure. While especially useful for those with large numbers of microservices, it can be useful for those lifting-and-shifting their existing monolithic application into a container environment.

### Installing Istio

By default, Istio uses a `LoadBalancer` type for its ingress gateway. That works fine if you're in AWS, Azure or GCP but doesn't work for an on-premises cluster and/or clusters in multiple public clouds or you just don't want to be tied to a cloud provider implementation. We also want to control the HTTP and HTTPS ports used by our own load balancer. To accomplish this, we'll create an additional values file for our install that specifies `NodePort` for the type of gateway and the ports we want to use for HTTP and HTTPS. (In this case we're using 35080 and 35443, respectively.)

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
```

We'll use the [Installing Istio](https://istio.io/docs/setup/#installing-istio) instructions. For our case, we're going to use the demo configuration option as it enables most of its functionality with minimal resource requirements. (For a comparison of the various options, see [Installation Configuration Profiles](https://istio.io/docs/setup/additional-setup/config-profiles/).)

```bash
$ kubectl create namespace istio-system
$ helm template istio-init install/kubernetes/helm/istio-init --namespace istio-system | kubectl apply -f -
$ helm template istio install/kubernetes/helm/istio --namespace istio-system --values install/kubernetes/helm/istio/values-istio-demo.yaml --values ./values-docker-enterprise.yaml | kubectl apply -f -
```

### Using Istio

The easiest way to demonstrate some of Istio's capabilities is to deploy the [Bookinfo](https://istio.io/docs/examples/bookinfo/). We'll start by creating and labeling the `bookinfo` namespace to enable automatic sidecar injection when we apply the Bookinfo manifests.

```bash
$ kubectl create namespace bookinfo
$ kubectl label namespace bookinfo istio-injection=enabled
$ kubectl -n bookinfo apply -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl -n bookinfo apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
$ kubectl -n bookinfo apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
```

The gateway and virtual service declarations specify '*' as the DNS name for the application. Since we'll be sharing this cluster for many services, we'll edit the gateway and virtual service to specify 'test-bookinfo.lab.capstonec.net' for the host and create a corresponding DNS CNAME entry that resolves to our cluster's load balancer. If I browse to http://test-bookinfo.lab.capstonec.net/productpage, I see the following.

If you keep refreshing the page you will see several Istio features in action. First, there are three versions of the reviews application and we've defined destination rules for each. One doesn't use the ratings service; the other two do. Of those two, one displays black stars and the other red stars. (See the following diagram.) Next, we've enabled mutual TLS (mTLS) between all of the services. Finally, there are four different programming languages in use and Istio enabled the destination rules and mTLS without having to change any of the services.

## Knative for Serverless

### What is Knative?

Knative was developed by Google (and others) to provide a serverless framework on top of Kubernetes. It allows developers to deploy their source code (functions) without worrying about the complexities of running containers. Knative then serves these functions up as running containers which are triggered by events on queues.

### Installing Knative

We will follow the [Install on a Kubernetes cluster](https://knative.dev/docs/install/knative-with-any-k8s/) instructions for installing Knative onto an existing Kubernetes cluster. (You may have to run the Knative CRD install more than once as there seems to be a race condition.) Also, we're not going to install the Knative monitoring manifest as we already have Prometheus and Grafana installed by our Istio install and we don't need the ELK stack as we typically install the Elastic Stack as part of our Kubernetes cluster install.

```bash
$ kubectl apply --selector knative.dev/crd-install=true \
   --filename https://github.com/knative/serving/releases/download/v0.10.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.10.0/release.yaml
```

```bash
$ kubectl apply \
   --filename https://github.com/knative/serving/releases/download/v0.10.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.10.0/release.yaml
```

By default, Knative uses the Istio ingress gateway for its serving component. Again, the gateway resource it creates uses '*' for the host DNS name. Since we're sharing this cluster, we'll edit it to use 'test-knative.lab.capstonec.net' and create the corresponding DNS CNAME entry.

[Setting up a custom domain](https://knative.dev/docs/serving/using-a-custom-domain/)

### Using Knative

[Getting Started with App Deployment](https://knative.dev/docs/serving/getting-started-knative-app/)

## Tekton for CI/CD

### What is Tekton?

Tekton provides a Kubernetes native framework for creating cloud-native CI/CD pipelines. It originated from Knative's build functionality.

### Installing Tekton

[Installing Tekton Pipelines](https://github.com/tektoncd/pipeline/blob/master/docs/install.md) is the easiest of the four.

```bash
$ kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

### Using Tekton

## Kubeflow for Machine Learning

### What is Kubeflow?

### Installing Kubeflow

I used [Kubeflow Deployment with kfctl_k8s_istio](https://www.kubeflow.org/docs/started/k8s/kfctl-k8s-istio/) to install Kubeflow but ran into a couple of problems. The first is documented; you have to comment out the istio-crds and istio-install applications from KfDef YAML file you use for the install since we've already installed Istio. The second isn't documented yet ([Issue #4469](https://github.com/kubeflow/kubeflow/issues/4469)); you also have to comment out the knative-serving-crds and knative-serving-install applications since we also have Knative installed already.

### Using Kubeflow

## Summary

Products like OpenShift are very perscriptive on how you do your work but you don't have to be. You can use all the same tools in your own Kubernetes cluster without being constrained by how another company thinks you should use them. For example, you may want to use [Linkerd](https://linkerd.io/) instead of Istio for your service mesh, [OpenFaaS](https://www.openfaas.com/) instead of Knative for serverless, and/or [Jenkins X](https://jenkins-x.io/) instead of Tekton for CI/CD. Or, maybe you have your own alternative to Kubeflow. One of the big advantages with using Docker Enterprise is the choice and flexibility it provides to build the infrastructure you need. If you want or need help, Capstone IT is a Docker Premier Consulting Partner as well as being an Azure Gold and AWS Select partner. If you are interested in finding out more and getting help with your Container, Cloud and DevOps transformation, please [Contact Us](https://capstonec.com/contact-us/).

Ken Rider
Solutions Architect
Capstone IT