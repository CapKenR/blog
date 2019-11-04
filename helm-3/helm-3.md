# A First Look at Helm 3

[Helm](https://helm.sh/) has been widely publicized as the package manager for [Kubernetes](https://kubernetes.io). We've seen the need over and over for Helm. Unfortunately, Helm 2 requires Tiller and Tiller opens a lot of security questions. In particular, in a multi-user, multi-organization, and/or multi-tenant cluster, securing the Tiller service account (or accounts) was difficult and problematic. As a result, we've never recommended our clients use Helm in production. With the recent announcement of the first release candidate for [Helm 3](https://v3.helm.sh/), it's time to take another look as this version no longer requires or uses Tiller so many (most) of our security concerns should be gone.

## Installing Helm 3

Installing Helm 3 is easy. Download the release from GitHub, uncompress the tar/zip file and move the binary to someplace in your path.

```bash
$ wget https://get.helm.sh/helm-v3.0.0-rc.2-linux-amd64.tar.gz
$ tar xzf helm-v3.0.0-rc.2-linux-amd64.tar.gz
$ mv linux-amd64/helm ~/.bin/
```

```bash
$ helm version
version.BuildInfo{Version:"v3.0.0-rc.2", GitCommit:"82ea5aa774661cc6557cb57293571d06f94aff0c", GitTreeState:"clean", GoVersion:"go1.13.3"}
```

## First Steps

In the past I've used the [nfs-client-provisioner](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner) Helm chart, to create a default storage class for my test Kubernetes clusters. The first thing I ran into was the `--name` command line option is no longer valid. With Helm 3 you now have to use the form `helm [command] [name] [chart]`.

```bash
$ helm install --name nfs-client-provisioner --set storageClass.defaultClass=true --set nfs.server=${FS_DNSNAME} --set nfs.path=/ stable/nfs-client-provisioner
Error: unknown flag: --name
```

The next thing I ran into is Helm 3 not being able to find my chart. Helm 3 stores the repository information in a separate (but now standard) location (under `~/.cache/helm/repository`) so we have to do a repository update in order to find charts from the default repository (since there isn't one now).

```bash
$ helm install --set storageClass.defaultClass=true --set nfs.server=${FS_DNSNAME} --set nfs.path=/ nfs-client-provisioner stable/nfs-client-provisioner
Error: failed to download "stable/nfs-client-provisioner" (hint: running `helm repo update` may help)
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
$ helm install --set storageClass.defaultClass=true --set nfs.server=${FS_DNSNAME} --set nfs.path=/ nfs-client-provisioner stable/nfs-client-provisioner
NAME: nfs-client-provisioner
LAST DEPLOYED: Sun Nov  3 18:00:37 2019
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

With Helm 2, you used the `delete` command with the `--purge` option to uninstall a chart and delete the history. With Helm 3, the delete command is an alias for the `uninstall` command and, by default, the history is deleted. (If you want to keep the history, you can use the `--keep-history` option.)

```bash
$ helm delete --purge nfs-client-provisioner
Error: unknown flag: --purge
$ helm uninstall nfs-client-provisioner
release "nfs-client-provisioner" uninstalled
```

## Setup our test environment 

In a past blog post, I setup [Functional Kubernetes Namespaces in Docker Enterprise](https://capstonec.com/dev-test-and-prod-k8s-namespaces-in-docker-ee/). We'll do that again here and see how Helm 3 handles our previous security concerns. As a reminder, the development team has the `edit` ClusterRole for the development namespace and the `view` ClusterRole for the test and production namespaces. The test team has the `view` role for the development and production namespaces and the `edit` role for the test namespace. And, the operations team has the `admin` role in all of those namespaces. Finally, we have a user without any defined rolebindings.

## Using Helm to deploy an application

In the following examples, we're going to use the [WordPress](https://github.com/helm/charts/tree/master/stable/wordpress) Helm chart. We'll start by having our development, test and operations teams deploy the same application into the development, test, and production namespaces, respectively. Then, we'll have our user with no privileges attempt to install it. To switch between users and namespaces, we'll use the `--namespace` and `--kubeconfig` options, respectively, to the `helm` command.

```bash
$ helm install --namespace development --kubeconfig joe-dev/kube.yml wordpress stable/wordpress
NAME: wordpress
LAST DEPLOYED: Mon Nov  4 15:44:34 2019
NAMESPACE: development
STATUS: deployed
REVISION: 1
NOTES:
1. Get the WordPress URL:

  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        Watch the status with: 'kubectl get svc --namespace development -w wordpress'
  export SERVICE_IP=$(kubectl get svc --namespace development wordpress --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
  echo "WordPress URL: http://$SERVICE_IP/"
  echo "WordPress Admin URL: http://$SERVICE_IP/admin"

2. Login with the following credentials to see your blog

  echo Username: user
  echo Password: $(kubectl get secret --namespace development wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)
```

```bash
$ helm install --namespace test --kubeconfig jane-test/kube.yml wordpress stable/wordpress
NAME: wordpress
LAST DEPLOYED: Mon Nov  4 15:45:23 2019
NAMESPACE: test
STATUS: deployed
REVISION: 1
NOTES:
1. Get the WordPress URL:

  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        Watch the status with: 'kubectl get svc --namespace test -w wordpress'
  export SERVICE_IP=$(kubectl get svc --namespace test wordpress --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
  echo "WordPress URL: http://$SERVICE_IP/"
  echo "WordPress Admin URL: http://$SERVICE_IP/admin"

2. Login with the following credentials to see your blog

  echo Username: user
  echo Password: $(kubectl get secret --namespace test wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)
```

```bash
$ helm install --namespace production --kubeconfig pat-ops/kube.yml wordpress stable/wordpress
NAME: wordpress
LAST DEPLOYED: Mon Nov  4 15:46:03 2019
NAMESPACE: production
STATUS: deployed
REVISION: 1
NOTES:
1. Get the WordPress URL:

  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        Watch the status with: 'kubectl get svc --namespace production -w wordpress'
  export SERVICE_IP=$(kubectl get svc --namespace production wordpress --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
  echo "WordPress URL: http://$SERVICE_IP/"
  echo "WordPress Admin URL: http://$SERVICE_IP/admin"

2. Login with the following credentials to see your blog

  echo Username: user
  echo Password: $(kubectl get secret --namespace production wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)
```

```bash
$ helm install --namespace default --kubeconfig arjun-nopriv/kube.yml wordpress stable/wordpress
Error: rendered manifests contain a resource that already exists. Unable to continue with install: could not get information about the resource: secrets "wordpress-mariadb" is forbidden: User "13607232-0375-4118-b20e-3ba6bb935f40" cannot get resource "secrets" in API group "" in the namespace "default": access denied
```

The first thing you will notice is that users from each of the teams could deploy the application in their respective namespace. Second, you may have noticed I used the same name for each of the installs. Names only have to be unique within a namespace not across all namespaces. Third, the user with no privileges couldn't install the chart, even in the default namespace.

## Viewing our Helm deployments

Now, let's see what each of these teams can see. You'll notice the development user can only see the charts installed in the development namespace. And, the operations user can see all of the installed charts (using the new `--all-namespaces` option in the second release candidate).

```bash
$ helm list --namespace production --kubeconfig joe-dev/kube.yml
NAME    NAMESPACE       REVISION        UPDATED STATUS  CHART   APP VERSION
$ helm list --namespace test --kubeconfig joe-dev/kube.yml
NAME    NAMESPACE       REVISION        UPDATED STATUS  CHART   APP VERSION
$ helm list --namespace development --kubeconfig joe-dev/kube.yml
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART          APP VERSION
wordpress       development     1               2019-11-04 15:44:34.300900099 +0000 UTC deployed        wordpress-7.6.15.2.4
```

```bash
$ helm list --all-namespaces --kubeconfig pat-ops/kube.yml
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART          APP VERSION
wordpress       development     1               2019-11-04 15:44:34.300900099 +0000 UTC deployed        wordpress-7.6.15.2.4
wordpress       test            1               2019-11-04 15:45:23.827980207 +0000 UTC deployed        wordpress-7.6.15.2.4
wordpress       production      1               2019-11-04 15:46:03.701766913 +0000 UTC deployed        wordpress-7.6.15.2.4
```

## Trying cross functional deployments

Next, let's see what a user can do in a namespace for which they don't have the necessary privileges to deploy an application. In this case, we'll have a development user attempt to deploy an application in the production namespace.

```bash
$ helm install --namespace production --kubeconfig joe-dev/kube.yml dev-wordpress stable/wordpress
Error: rendered manifests contain a resource that already exists. Unable to continue with install: could not get information about the resource: secrets "dev-wordpress-mariadb" is forbidden: User "6dda6713-6aa5-474f-93be-c8bb50cafeef" cannot get resource "secrets" in API group "" in the namespace "production": access denied
```

The development user doesn't have permission to get secrets in the production namespace and Helm 3 uses secrets (rather than Tiller) to manage chart installs in the namespace. As a result, the development user can't install a chart in the production namespace. (Of course, we could give the development team the ability to manage secrets in the production namespace but we'd be back to our original security concerns.)

## Helm Secrets

If you can't get secrets in a namespace, you can't list (or install or uninstall) charts installed in that namespace. As a cluster admin, we can see the secrets Helm 3 created in each of the namespaces where charts have been installed.

```bash
$ kubectl get secrets --all-namespaces | grep helm
NAMESPACE         NAME                                             TYPE                                  DATA   AGE
development       sh.helm.release.v1.wordpress.v1                  helm.sh/release.v1                    1      15m
production        sh.helm.release.v1.wordpress.v1                  helm.sh/release.v1                    1      13m
test              sh.helm.release.v1.wordpress.v1                  helm.sh/release.v1                    1      14m

$ kubectl describe secret sh.helm.release.v1.wordpress.v1 -n development
Name:         sh.helm.release.v1.wordpress.v1
Namespace:    development
Labels:       modifiedAt=1572882276
              name=wordpress
              owner=helm
              status=deployed
              version=1
Annotations:  <none>

Type:  helm.sh/release.v1

Data
====
release:  33836 bytes

$ kubectl get secret sh.helm.release.v1.wordpress.v1 -n development -o json | jq -r .data.release | base64 --decode -
H4sIAAAAAAAC/+y9CXOj...
```

Even though we can (as a cluster admin) decode the secrets, we're still left with a non-text string so there's not a lot of information we can get from it. (Maybe someone has a way to further "decode" this secret but I haven't run across it yet.)

## Summary

We've now taken our first look at Helm 3. It appears as if it has addressed the security problems we've seen in the past with Tiller. We'll be doing more testing with Helm as a result. A lot is going on in this space. If you want or need help, Capstone IT is a Docker Premier Consulting Partner as well as being an Azure Gold and AWS Select partner. If you are interested in finding out more and getting help with your Container, Cloud and DevOps transformation, please [Contact Us](https://capstonec.com/contact-us/).

Ken Rider
Solutions Architect
Capstone IT