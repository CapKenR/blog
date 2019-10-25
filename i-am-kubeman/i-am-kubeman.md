# I Am Kubeman

I never thought I'd be going to Walmart for technology tools, advice, etc. However, thanks to Aymen EL Amri's great curated weekly email, Kaptain, on all things Kubernetes, see https://www.faun.dev/, I ran across a great tool from Walmart Labs called [Kubeman](https://github.com/walmartlabs/kubeman). If you are managing multiple Kubernetes clusters, and that's almost always the case if you're using Kubernetes, Kubeman is a tool you need to consider for troubleshooting. In addition to making it easier to investigate issues across multiple Kubernetes clusters, it understands the Istio service mesh as well.

## Install Kubeman

The easiest way to install Kubeman is with one of the pre-built binaries for Linux, Windows or Mac. You can find them at https://github.com/walmartlabs/kubeman/releases. The current release, 0.5, is their first public release.

## Kubernetes Configuration

In order to use Kubeman, you must first connect to your Kubernetes cluster using kubectl in order to save the context to your local kube config. Kubeman uses your local kube config to determine which cluster(s) will be available to you. In my case, I have two Kubernetes clusters, one in AWS and the other in Azure. I used [Docker Enterprise](https://www.docker.com/products/docker-enterprise) to create both clusters. Each cluster has one Universal Control Plane (UCP) server, one Docker Trusted Registry (DTR) server and 2 Linux worker servers. On each cluster I have two users; the default admin user with cluster administration privileges and another user, ken, with admin privileges on one namespace, kens-namespace.

Docker Enterprise includes a great feature called a client bundle which makes it easy to obtain and/or setup the environment variables, user and server certificates and configuration files. (For more details, see Brian Kaufman's blog post, [Get Familiar with Docker Enterprise Edition Client Bundles](https://www.docker.com/blog/get-familiar-docker-enterprise-edition-client-bundles/).) I've downloaded and executed the client bundle for each user on each cluster. If I look at my Kubernetes configuration, I see the following clusters, contexts, and users.

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
- name: ucp_test-aws-ucp.lab.capstonec.net:6443_ken
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: ucp_test-azure-ucp.lab.capstonec.net:6443_admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: ucp_test-azure-ucp.lab.capstonec.net:6443_ken
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```
