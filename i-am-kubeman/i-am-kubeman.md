# I Am Kubeman

I never thought I'd be going to Walmart for technology tools, advice, etc. However, thanks to Aymen EL Amri's great curated weekly email, Kaptain, on all things Kubernetes, see https://www.faun.dev/, I ran across a great tool from [Walmart Labs](https://code.walmartlabs.com/) called [Kubeman](https://github.com/walmartlabs/kubeman). If you are managing multiple Kubernetes clusters, and that's almost always the case if you're using Kubernetes, Kubeman is a tool you need to consider for troubleshooting. In addition to making it easier to investigate issues across multiple Kubernetes clusters, it understands an [Istio](https://istio.io/) service mesh as well.

## Install Kubeman

The easiest way to install Kubeman is with one of the pre-built binaries for Linux, Windows or Mac. You can find them at https://github.com/walmartlabs/kubeman/releases. The current release, 0.5, is their first public release.

## Kubernetes Configuration

To use Kubeman, you must first connect to your Kubernetes cluster using kubectl to save the context to your local kube config. Kubeman uses your local kube config to determine which cluster(s) will be available to you. In my case, I have two Kubernetes clusters, one in AWS and the other in Azure. I used [Docker Enterprise](https://www.docker.com/products/docker-enterprise) to create both clusters. On each cluster I have two users; the default admin user with cluster administration privileges and another user, kenrider, with admin privileges on one namespace, default.

Docker Enterprise includes a great feature called a client bundle which makes it easy to obtain and/or setup the environment variables, user and server certificates, and configuration files. (For more details, see Brian Kaufman's blog post, [Get Familiar with Docker Enterprise Edition Client Bundles](https://www.docker.com/blog/get-familiar-docker-enterprise-edition-client-bundles/).) I've downloaded and executed the client bundle for each user on each cluster. If I look at my Kubernetes configuration, I see the following clusters, contexts, and users.

```bash
$ kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://test-aws-ucp.lab.capstonec.net:6443
  name: ucp_test-aws-ucp.lab.capstonec.net:6443_admin
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://test-azure-ucp.lab.capstonec.net:6443
  name: ucp_test-aws-azure.lab.capstonec.net:6443_admin
contexts:
- context:
    cluster: ucp_test-aws-ucp.lab.capstonec.net:6443_admin
    user: ucp_test-aws-ucp.lab.capstonec.net:6443_admin
  name: ucp_test-aws-ucp.lab.capstonec.net:6443_admin
- context:
    cluster: ucp_test-azure-ucp.lab.capstonec.net:6443_admin
    user: ucp_test-azure-ucp.lab.capstonec.net:6443_admin
  name: ucp_test-azure-ucp.lab.capstonec.net:6443_admin
current-context: ""
kind: Config
preferences: {}
users:
- name: ucp_test-aws-ucp.lab.capstonec.net:6443_admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: ucp_test-aws-ucp.lab.capstonec.net:6443_kenrider
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: ucp_test-azure-ucp.lab.capstonec.net:6443_admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: ucp_test-azure-ucp.lab.capstonec.net:6443_kenrider
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```

## Istio Configuration

In the AWS-hosted cluster, I've installed the current version (1.3.4 at the time I'm writing this post) of the Istio service mesh. And, in the Azure-hosted cluster, I used the previous version, 1.3.3. In both cases, I installed it using the demonstration configuration which enables most of its features but with limited resource utilization.

## Sample Istio Application

The Istio project has a sample application, [Bookinfo](https://istio.io/docs/examples/bookinfo/), that I've deployed as the `kenrider` user in the `default` namespace on both clusters. In the Azure cluster, I also applied an Istio gateway and virtual service as well as destination rules for the three microservices and versions.

## Kubeman Recipes

From the Kubeman documentation, "_Kubeman offers various recipes ranging from those that can give you a summary overview of a cluster, to those that can analyze and correlate configurations across multiple clusters._" These recipes are grouped into categories like Cluster, Events, Resources, Istio Ingress, etc. Within each category, there are 2 to 21 recipes. It's obvious from the recipes that Walmart is a big Istio user but there are quite a few good, generic Kubernetes recipes even if you aren't using Istio. The Kubeman [user guide](https://github.com/walmartlabs/kubeman/blob/master/userGuide.md) takes you through all of the available recipes so let's take a look at some of my favorites and why you might use them.

### Clusters Overview

The Cluster Overview recipe does exactly what the name implies. You can see the nodes, versions, etc. for multiple clusters in one place at the same time.

### List/Compare Secrets

The List/Compare Secrets recipe lets you see the secrets in multiple namespaces and/or clusters. And, it identifies where there are differences between them. In my case, I'm looking at the default and istio-system namespaces in my two clusters. Here you can see in the default namespace the cluster in Azure is missing the NFS client provisioner related secrets which point to a problem I had installing it there. In the istio-system namespace, the differences in secrets are related to the cloud provider and are expected.

### View All Resources in a Namespace

Unlike the `kubectl get all` command, the View All Resources in a Namespace recipe truly does show you all resources. In addition, you can see the details of each resource without having to issue another `kubectl` command.

### Compare Two Deployments

Again, the Compare Two Deployments recipe does exactly what it implies. In the example below I'm comparing the v1 and v2 deployments of the reviews microservice that is part of the bookinfo sample Istio application. But, you could also use this recipe to compare the same deployment in two different namespaces or two different clusters.

### Analyze Service mTLS Status

Troubleshooting an mTLS configuration in Istio requires multiple `istioctl` and `kubectl` commands and, sometimes, exec'ing into containers. The Analyze Service mTLS Status recipe (and other related recipes) can make it a lot easier to view and understand. In this example, we've configured permissive mTLS for the bookinfo microservices.

## What's Missing or Wrong?

The biggest thing I see missing is you can't edit recipes and you can't create your own recipes. For example, I have [Knative](https://knative.dev/) (serverless) and [Tekton Pipelines](https://tekton.dev/) (CI/CD) deployed in another Kubernetes cluster. It would be nice to be able to add recipes specific to troubleshooting those application workflows. Since Walmart Labs has open-sourced the project, I could modify the code to add my recipes to it. But, if you don't know TypeScript or you're not a developer that's not an option.

Kubeman isn't to a 1.0 version yet so the things I've found wrong should be taken with a grain of salt. Having said that, I have found situations where it doesn't seem to like a context even though kubectl doesn't have a problem communicating as that user with that cluster. And, I've seen cases where some of the recipes don't work for me.

## Summary

Troubleshooting Kubernetes and Istio are hard. Kubeman has a lot of promise for making it easier. Even though I ran into some challenges along the way and there is still work to be done, I would recommend checking it out. If you want or need help with your Kubernetes journey, Capstone IT is a Docker Premier Consulting Partner as well as being an Azure Gold and AWS Select partner. If you are interested in finding out more and getting help with your Container, Cloud and DevOps transformation, please [Contact Us](https://capstonec.com/contact-us/).

[Ken Rider](https://www.linkedin.com/in/kenrider)  
Solutions Architect  
Capstone IT