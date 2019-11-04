# A First Look at Helm 3

[Helm](https://helm.sh/) has been widely publicized as the package manager for [Kubernetes](https://kubernetes.io). We've seen the need over and over for Helm. Unfortunately, Helm 2 requires Tiller and Tiller opens a lot of security questions. In particular, in a multi-user, multi-organization, and/or multi-tenant cluster, securing the Tiller service account (or accounts) was difficult and problematic. As a result, we've never recommended our clients use Helm in production. With the recent announcement of the first release candidate for [Helm 3](https://v3.helm.sh/), it's time to take another look as this version no longer requires or uses Tiller so many (most) of our security concerns should be gone.

## Installing Helm 3

```bash
$ helm version
version.BuildInfo{Version:"v3.0.0-rc.1", GitCommit:"ee77ae3d40fd599445ebd99b8fc04e2c86ca366c", GitTreeState:"clean", GoVersion:"go1.13.3"}
```

## First Steps

```bash
$ helm install --name nfs-client-provisioner --set storageClass.defaultClass=true --set nfs.server=${FS_DNSNAME} --set nfs.path=/ stable/nfs-client-provisioner
Error: unknown flag: --name
```

```bash
$ helm install --set storageClass.defaultClass=true --set nfs.server=${FS_DNSNAME} --set nfs.path=/ nfs-client-provisioner stable/nfs-client-provisioner
Error: failed to download "stable/nfs-client-provisioner" (hint: running `helm repo update` may help)
```

```bash
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

```bash
$ helm install --set storageClass.defaultClass=true --set nfs.server=${FS_DNSNAME} --set nfs.path=/ nfs-client-provisioner stable/nfs-client-provisioner
NAME: nfs-client-provisioner
LAST DEPLOYED: Sun Nov  3 18:00:37 2019
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

```bash
$ helm delete --purge nfs-client-provisioner
Error: unknown flag: --purge
```

```bash
$ helm uninstall nfs-client-provisioner
release "nfs-client-provisioner" uninstalled
```

## Setup our test environment 

In a past blog post, I setup [Functional Kubernetes Namespaces in Docker Enterprise](https://capstonec.com/dev-test-and-prod-k8s-namespaces-in-docker-ee/). We'll do that again here and see how Helm 3 handles our previous security concerns.

## Using Helm to deploy an application

We'll start by having our development, test and operations teams deploy the same application into the development, test, and production namespaces, respectively.

## Viewing our Helm deployments

Now, let's see what each of these teams can see. We'll use the `--kubeconfig` option to the `helm` command line to switch between users from each respective team.

## Trying cross functional deployments

Next, let's see what each can do in each of the namespaces.

