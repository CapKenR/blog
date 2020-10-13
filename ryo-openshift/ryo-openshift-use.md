# Roll Your Own Developer Experience

Late last year a Red Hat press release, [Red Hat Expands the Kubernetes Developer Experience with Newest Version of Red Hat OpenShift 4](https://www.redhat.com/en/about/press-releases/red-hat-expands-kubernetes-developer-experience-newest-version-red-hat-openshift-4), talked about the new developer services they included in OpenShift 4.2. However, these services are not confined to OpenShift. In reality, their Service Mesh service is [Istio](https://istio.io), their Serverless service is [Knative](https://knative.dev/), and their Pipelines service is [Tekton Pipelines](https://tekton.dev/). In the past, Red Hat has talked about running a machine learning toolkit, [KubeFlow](https://www.kubeflow.org/), in OpenShift as well. Over the past year I've had the opportunity to run each of these services in Kubernetes clusters built using Mirantis' [Docker Enterprise](https://www.mirantis.com/software/docker/docker-enterprise/) or VMware's [Tanzu Kubernetes Grid](https://tanzu.vmware.com/kubernetes-grid). In this post, I'll show you how to roll your own developer experience by bringing them all up in your own cluster.

Full disclosure... I had this post almost ready to go many months ago. All I had to do was some minor editing but then life and work got in the way. And, over that time Istio went through a major architectural change, Kubeflow released their 1.0 version, and everything else went through one or two patches and/or upgrades. It should be noted that keeping up with the rate of change is one of the big challenges with doing it yourself. As a result, I went back and re-did everything using the latest version of each application.

## Istio for Service Mesh

### Using Istio

The easiest way to demonstrate some of Istio's capabilities is to deploy the [Bookinfo](https://istio.io/docs/examples/bookinfo/) sample application. We'll start by creating and labeling the `bookinfo` namespace to enable automatic sidecar injection when we apply the Bookinfo manifests.

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

### Using Knative

[Getting Started with App Deployment](https://knative.dev/docs/serving/getting-started-knative-app/)

```bash
$ kn service create helloworld-go --image gcr.io/knative-samples/helloworld-go --env TARGET="Go Sample v1"
```

## Tekton for CI/CD

### Using Tekton

## Kubeflow for Machine Learning

### Using Kubeflow

## Summary

Products like OpenShift are very perscriptive on how you do your work but you don't have to be. You can use all the same or similar tools in your own Kubernetes cluster without being constrained by how another company thinks you should use them. For example, you may want to use [Linkerd](https://linkerd.io/) instead of Istio for your service mesh, [OpenFaaS](https://www.openfaas.com/) instead of Knative for serverless, and/or [GitLab](https://about.gitlab.com/) instead of Tekton for CI/CD. Or, maybe you have your own alternative to Kubeflow. One of the big advantages with using Kubernetes is the choice and flexibility it provides to build the infrastructure you need. If you want or need help, Capstone IT is a VMware Modern Applications Professional partner and a Docker Premier Consulting Partner as well as being an Azure Gold and AWS Select partner. If you are interested in finding out more and getting help with your digital transformation using Kubernetes, Cloud, and DevOps, please [Contact Us](https://capstonec.com/contact/).

[Ken Rider](https://www.linkedin.com/in/kenrider)  
Solutions Architect  
Capstone IT