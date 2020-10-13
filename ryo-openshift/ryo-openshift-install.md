# Roll Your Own Developer Experience

Late last year a Red Hat press release, [Red Hat Expands the Kubernetes Developer Experience with Newest Version of Red Hat OpenShift 4](https://www.redhat.com/en/about/press-releases/red-hat-expands-kubernetes-developer-experience-newest-version-red-hat-openshift-4), talked about the new developer services they included in OpenShift 4.2. However, these services are not confined to OpenShift. In reality, their Service Mesh service is [Istio](https://istio.io), their Serverless service is [Knative](https://knative.dev/), and their Pipelines service is [Tekton Pipelines](https://tekton.dev/). In the past, Red Hat has talked about running a machine learning toolkit, [KubeFlow](https://www.kubeflow.org/), in OpenShift as well. Over the past year I've had the opportunity to run each of these services in Kubernetes clusters built using Mirantis' [Docker Enterprise](https://www.mirantis.com/software/docker/docker-enterprise/) or VMware's [Tanzu Kubernetes Grid](https://tanzu.vmware.com/kubernetes-grid). In this post, I'll show you how to roll your own developer experience by bringing them all up in your own cluster.

Full disclosure... I had this post almost ready to go many months ago. All I had to do was some minor editing but then life and work got in the way. And, over that time Istio went through a major architectural change, Kubeflow released their 1.0 version, and everything else went through one or two patches and/or upgrades. It should be noted that keeping up with the rate of change is one of the big challenges with doing it yourself. As a result, I went back and re-did everything using the latest version of each application.

## Istio for Service Mesh

### What is Istio?

As a service mesh implementation, Istio helps to remove the complexity from connecting, securing, controlling, and observing services deployed in a Kubernetes infrastructure. While especially useful for those with large numbers of microservices, it is also useful for those lifting-and-shifting their existing monolithic application into a container environment.

### Installing Istio

By default, Istio uses a `LoadBalancer` type for its ingress gateway. That works fine if you're in AWS, Azure or GCP but doesn't work for an on-premises cluster and/or clusters in multiple public clouds or you just don't want to be tied to a cloud provider implementation. We also want to control the HTTP and HTTPS ports used by our own load balancer. To accomplish this, we'll create an additional values file for our install that specifies `NodePort` for the type of gateway and the ports we want to use for HTTP and HTTPS. (In this case we're using 35080 and 35443, respectively. And, we're only showing the portion of the demo.yaml profile that changed.)

```yaml demo-docker-enterpise.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          ports:
            - port: 15021
              targetPort: 15021
              name: status-port
            - port: 80
              targetPort: 8080
              name: http2
              nodePort: 35080
            - port: 443
              targetPort: 8443
              name: https
              nodePort: 35443
            - port: 31400
              targetPort: 31400
              name: tcp
            - port: 15443
              targetPort: 15443
              name: tls
```

We'll use the [Install with Istioctl](https://istio.io/latest/docs/setup/install/istioctl/) instructions. For our case, we're going to use the demo configuration option as it enables most of its functionality with minimal resource requirements. (For a comparison of the various options, see [Installation Configuration Profiles](https://istio.io/docs/setup/additional-setup/config-profiles/).) Note: previously we would have used Helm to install Istio but, with the 1.5 release, Helm is being depracated in favor of istioctl.

```bash
$ istioctl install --filename demo-docker-enterprise.yaml
Detected that your cluster does not support third party JWT authentication. Falling back to less secure first party JWT. See https://istio.io/docs/ops/best-practices/security/#configure-third-party-service-account-tokens for details.
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Egress gateways installed
✔ Installation complete                                                                                                 
```

Now that we have Istio installed, let's move on to Knative.

## Knative for Serverless

### What is Knative?

Knative was developed by Google (and others) to provide a serverless framework on top of Kubernetes. It allows developers to deploy their source code (functions) without worrying about the complexities of running containers. Knative then serves these functions up as running containers which are triggered by events on queues.

### Installing Knative

We will follow the [Install on a Kubernetes cluster](https://knative.dev/docs/install/knative-with-any-k8s/) instructions for installing Knative onto an existing Kubernetes cluster. (You may have to run the Knative CRD install more than once as there seems to be a race condition.) Also, we're not going to install the Knative monitoring manifest as we already have Prometheus and Grafana installed by our Istio install and we don't need the ELK stack as we typically install the Elastic Stack as part of our Kubernetes cluster install.

### Setup Knative Serving

Install the Knative serving Custom Resource Definitions (CRDs).

```bash
$ kubectl apply --filename https://github.com/knative/serving/releases/download/v0.18.0/serving-crds.yaml
customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/ingresses.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/metrics.autoscaling.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/podautoscalers.autoscaling.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/revisions.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/routes.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/serverlessservices.networking.internal.knative.dev created
customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev created
customresourcedefinition.apiextensions.k8s.io/images.caching.internal.knative.dev created
```

Install the Knative serving core resources.

```bash
$ kubectl apply --filename https://github.com/knative/serving/releases/download/v0.18.0/serving-core.yaml
namespace/knative-serving created
clusterrole.rbac.authorization.k8s.io/knative-serving-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-edit created
clusterrole.rbac.authorization.k8s.io/knative-serving-namespaced-view created
clusterrole.rbac.authorization.k8s.io/knative-serving-core created
clusterrole.rbac.authorization.k8s.io/knative-serving-podspecable-binding created
serviceaccount/controller created
clusterrole.rbac.authorization.k8s.io/knative-serving-admin created
clusterrolebinding.rbac.authorization.k8s.io/knative-serving-controller-admin created
customresourcedefinition.apiextensions.k8s.io/images.caching.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/certificates.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/configurations.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/ingresses.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/metrics.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/podautoscalers.autoscaling.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/revisions.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/routes.serving.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/serverlessservices.networking.internal.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/services.serving.knative.dev unchanged
image.caching.internal.knative.dev/queue-proxy created
configmap/config-autoscaler created
configmap/config-defaults created
configmap/config-deployment created
configmap/config-domain created
configmap/config-features created
configmap/config-gc created
configmap/config-leader-election created
configmap/config-logging created
configmap/config-network created
configmap/config-observability created
configmap/config-tracing created
horizontalpodautoscaler.autoscaling/activator created
poddisruptionbudget.policy/activator-pdb created
deployment.apps/activator created
service/activator-service created
deployment.apps/autoscaler created
service/autoscaler created
deployment.apps/controller created
service/controller created
deployment.apps/webhook created
service/webhook created
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.serving.knative.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.serving.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.serving.knative.dev created
secret/webhook-certs created
```

Configure the `knative-serving` namespace to automatically inject the Istio sidecar into pods in that namespace.

```bash
$ kubectl label namespace knative-serving istio-injection=enabled
namespace/knative-serving labeled
```

Set the Istio MTLS mode to `PERMISSIVE` for the `knative-serving` namespace.

```bash
$ cat <<EOF | kubectl apply -f -
> apiVersion: "security.istio.io/v1beta1"
> kind: "PeerAuthentication"
> metadata:
>   name: "default"
>   namespace: "knative-serving"
> spec:
>   mtls:
>     mode: PERMISSIVE
> EOF
peerauthentication.security.istio.io/default created
```

Install the Knative resources for using Istio's networking resources.

```bash
$ kubectl apply --filename https://github.com/knative/net-istio/releases/download/v0.18.0/release.yaml
clusterrole.rbac.authorization.k8s.io/knative-serving-istio created
gateway.networking.istio.io/knative-ingress-gateway created
gateway.networking.istio.io/cluster-local-gateway created
gateway.networking.istio.io/knative-local-gateway created
service/knative-local-gateway created
peerauthentication.security.istio.io/webhook created
peerauthentication.security.istio.io/istio-webhook created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.istio.networking.internal.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.istio.networking.internal.knative.dev created
secret/istio-webhook-certs created
configmap/config-istio created
deployment.apps/networking-istio created
deployment.apps/istio-webhook created
service/istio-webhook created
```

### Setup Knative Eventing

Install the Knative eventing CRDs.

```bash
$ kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.18.0/eventing-crds.yaml
customresourcedefinition.apiextensions.k8s.io/apiserversources.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/brokers.eventing.knative.dev created
customresourcedefinition.apiextensions.k8s.io/channels.messaging.knative.dev created
customresourcedefinition.apiextensions.k8s.io/containersources.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/eventtypes.eventing.knative.dev created
customresourcedefinition.apiextensions.k8s.io/parallels.flows.knative.dev created
customresourcedefinition.apiextensions.k8s.io/pingsources.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/sequences.flows.knative.dev created
customresourcedefinition.apiextensions.k8s.io/sinkbindings.sources.knative.dev created
customresourcedefinition.apiextensions.k8s.io/subscriptions.messaging.knative.dev created
customresourcedefinition.apiextensions.k8s.io/triggers.eventing.knative.dev created
```

Install the Knative eventing core resources.

```bash
$ kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.18.0/eventing-core.yaml
namespace/knative-eventing created
serviceaccount/eventing-controller created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-resolver created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-source-observer created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-sources-controller created
clusterrolebinding.rbac.authorization.k8s.io/eventing-controller-manipulator created
serviceaccount/pingsource-mt-adapter created
clusterrolebinding.rbac.authorization.k8s.io/knative-eventing-pingsource-mt-adapter created
serviceaccount/eventing-webhook created
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook created
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook-resolver created
clusterrolebinding.rbac.authorization.k8s.io/eventing-webhook-podspecable-binding created
configmap/config-br-default-channel created
configmap/config-br-defaults created
configmap/default-ch-webhook created
configmap/config-leader-election created
configmap/config-logging created
configmap/config-observability created
configmap/config-tracing created
deployment.apps/eventing-controller created
deployment.apps/pingsource-mt-adapter created
deployment.apps/eventing-webhook created
service/eventing-webhook created
customresourcedefinition.apiextensions.k8s.io/apiserversources.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/brokers.eventing.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/channels.messaging.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/containersources.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/eventtypes.eventing.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/parallels.flows.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/pingsources.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/sequences.flows.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/sinkbindings.sources.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/subscriptions.messaging.knative.dev unchanged
customresourcedefinition.apiextensions.k8s.io/triggers.eventing.knative.dev unchanged
clusterrole.rbac.authorization.k8s.io/addressable-resolver created
clusterrole.rbac.authorization.k8s.io/service-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/serving-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/channel-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/broker-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/messaging-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/flows-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/eventing-broker-filter created
clusterrole.rbac.authorization.k8s.io/eventing-broker-ingress created
clusterrole.rbac.authorization.k8s.io/eventing-config-reader created
clusterrole.rbac.authorization.k8s.io/channelable-manipulator created
clusterrole.rbac.authorization.k8s.io/meta-channelable-manipulator created
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-messaging-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-flows-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-sources-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-bindings-namespaced-admin created
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-edit created
clusterrole.rbac.authorization.k8s.io/knative-eventing-namespaced-view created
clusterrole.rbac.authorization.k8s.io/knative-eventing-controller created
clusterrole.rbac.authorization.k8s.io/knative-eventing-pingsource-mt-adapter created
clusterrole.rbac.authorization.k8s.io/podspecable-binding created
clusterrole.rbac.authorization.k8s.io/builtin-podspecable-binding created
clusterrole.rbac.authorization.k8s.io/source-observer created
clusterrole.rbac.authorization.k8s.io/eventing-sources-source-observer created
clusterrole.rbac.authorization.k8s.io/knative-eventing-sources-controller created
clusterrole.rbac.authorization.k8s.io/knative-eventing-webhook created
validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.eventing.knative.dev created
mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.eventing.knative.dev created
validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.eventing.knative.dev created
secret/eventing-webhook-certs created
mutatingwebhookconfiguration.admissionregistration.k8s.io/sinkbindings.webhook.sources.knative.dev created
```

Install the In-Memory (standalone) default Channel (messaging) layer. (Apache Kafka, Google Cloud Pub/Sub, and NATS channels are also available.)

```bash
$ kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.18.0/in-memory-channel.yaml
configmap/config-imc-event-dispatcher created
clusterrole.rbac.authorization.k8s.io/imc-addressable-resolver created
clusterrole.rbac.authorization.k8s.io/imc-channelable-manipulator created
clusterrole.rbac.authorization.k8s.io/imc-controller created
serviceaccount/imc-controller created
clusterrole.rbac.authorization.k8s.io/imc-dispatcher created
service/imc-dispatcher created
serviceaccount/imc-dispatcher created
clusterrolebinding.rbac.authorization.k8s.io/imc-controller created
clusterrolebinding.rbac.authorization.k8s.io/imc-dispatcher created
customresourcedefinition.apiextensions.k8s.io/inmemorychannels.messaging.knative.dev created
deployment.apps/imc-controller created
deployment.apps/imc-dispatcher created
```

Install the MT-Channel-based Broker (eventing) layer. (An Apache Kafka broker is available as well.)

```bash
$ kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.18.0/mt-channel-broker.yaml
clusterrole.rbac.authorization.k8s.io/knative-eventing-mt-channel-broker-controller created
clusterrole.rbac.authorization.k8s.io/knative-eventing-mt-broker-filter created
serviceaccount/mt-broker-filter created
clusterrole.rbac.authorization.k8s.io/knative-eventing-mt-broker-ingress created
serviceaccount/mt-broker-ingress created
clusterrolebinding.rbac.authorization.k8s.io/eventing-mt-channel-broker-controller created
clusterrolebinding.rbac.authorization.k8s.io/knative-eventing-mt-broker-filter created
clusterrolebinding.rbac.authorization.k8s.io/knative-eventing-mt-broker-ingress created
deployment.apps/mt-broker-filter created
service/broker-filter created
deployment.apps/mt-broker-ingress created
service/broker-ingress created
deployment.apps/mt-broker-controller created
horizontalpodautoscaler.autoscaling/broker-ingress-hpa created
horizontalpodautoscaler.autoscaling/broker-filter-hpa created
```

By default, Knative uses the Istio ingress gateway for its serving component. Again, the gateway and virtual service resources it creates use '*' for the host DNS name. Since we're sharing this cluster, we'll edit it to use 'test-knative.lab.capstonec.net' and create the corresponding DNS CNAME entry.

[Setting up a custom domain](https://knative.dev/docs/serving/using-a-custom-domain/)

## Tekton for CI/CD

### What is Tekton?

Tekton provides a Kubernetes native framework for creating cloud-native CI/CD pipelines. It originated from Knative's build functionality.

### Installing Tekton

[Installing Tekton Pipelines](https://github.com/tektoncd/pipeline/blob/master/docs/install.md) is the easiest of the four.

```bash
$ kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

## Kubeflow for Machine Learning

### What is Kubeflow?

### Installing Kubeflow

I used [Kubeflow Deployment with kfctl_k8s_istio](https://www.kubeflow.org/docs/started/k8s/kfctl-k8s-istio/) to install Kubeflow but ran into a couple of problems. The first is documented; you have to comment out the istio-crds and istio-install applications from the KfDef YAML file you use for the install since we've already installed Istio. The second isn't documented yet ([Issue #4469](https://github.com/kubeflow/kubeflow/issues/4469)); you also have to comment out the knative-serving-crds and knative-serving-install applications since we also have Knative installed already.

## Summary

Products like OpenShift are very perscriptive on how you do your work but you don't have to be. You can use all the same or similar tools in your own Kubernetes cluster without being constrained by how another company thinks you should use them. For example, you may want to use [Linkerd](https://linkerd.io/) instead of Istio for your service mesh, [OpenFaaS](https://www.openfaas.com/) instead of Knative for serverless, and/or [GitLab](https://about.gitlab.com/) instead of Tekton for CI/CD. Or, maybe you have your own alternative to Kubeflow. One of the big advantages with using Kubernetes is the choice and flexibility it provides to build the infrastructure you need. If you want or need help, Capstone IT is a VMware Modern Applications Professional partner and a Docker Premier Consulting Partner as well as being an Azure Gold and AWS Select partner. If you are interested in finding out more and getting help with your digital transformation using Kubernetes, Cloud, and DevOps, please [Contact Us](https://capstonec.com/contact/).

[Ken Rider](https://www.linkedin.com/in/kenrider)  
Solutions Architect  
Capstone IT