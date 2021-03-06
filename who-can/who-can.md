# Who Can...?

Managing a Kubernetes cluster with one user is easy. Once you go beyond one user, you need to start using Role-Based Access Control (RBAC). I've delved into this topic several times in the past with posts on how to [Create a Kubernetes User Sandbox in Docker Enterprise](https://capstonec.com/create-a-user-k8s-sandbox-in-docker-ee/) and [Functional Kubernetes Namespaces in Docker Enterprise](https://capstonec.com/dev-test-and-prod-k8s-namespaces-in-docker-ee/). But, once you get beyond a couple of users and/or teams and a few namespaces for them, it quickly becomes difficult to keep track of who can do what and where. And, as time goes on and more and more people have a hand in setting up your RBAC, it can get even more confusing. You can and should have your RBAC resource definitions in source control but it's not easy to read and is hard to visualize. Enter the open source [who-can](https://github.com/aquasecurity/kubectl-who-can) kubectl plugin from the folks at [Aqua Security](https://www.aquasec.com/). It gives you the ability to show who (subjects) can do what (verbs) to what (resources) and where (namespaces).

## Install the Krew Plugin Manager

The who-can plugin for kubectl requires the krew plugin manager. If you don't already have krew installed, the instructions for installing it can be found on its GitHub repository, https://github.com/kubernetes-sigs/krew/. To verify it's installed correctly, you can get a list of available plugins from kubectl.

```bash
$ kubectl plugin list
The following kubectl-compatible plugins are available:

/home/ken.rider/.krew/bin/kubectl-krew
```

## Install the Who-Can Plugin

Once you have the krew plugin manager for kubectl, installing the who-can plugin is easy.

```bash
$ kubectl krew install who-can
```

## Setting up RBAC for our Cluster

Now that we have who-can installed, let's try it out. I have a Kubernetes cluster I built in Azure using [Docker Enterprise](https://www.docker.com/products/docker-enterprise). I have 3 (non-default) namespaces for development, test, and production. I also have teams for development, test, operations, and security which I've created as a cluster admin user. I've defined a set of RoleBindings for each along the lines of those I used in my blog post on functional namespaces but taking advantage of the default ClusterRoles created with the Docker Enterprise installation. (See https://github.com/CapKenR/blog/tree/master/who-can for details on the RBAC definition I'm using here.)

```bash
$ kubectl apply -f development-namespace.yaml
namespace/development created
rolebinding.rbac.authorization.k8s.io/dev-team:development-edit created
rolebinding.rbac.authorization.k8s.io/test-team:development-view created
rolebinding.rbac.authorization.k8s.io/ops-team:development-admin created
rolebinding.rbac.authorization.k8s.io/sec-team:development-view created
$ kubectl apply -f test-namespace.yaml
namespace/test created
rolebinding.rbac.authorization.k8s.io/dev-team:test-view created
rolebinding.rbac.authorization.k8s.io/test-team:test-edit created
rolebinding.rbac.authorization.k8s.io/ops-team:test-admin created
rolebinding.rbac.authorization.k8s.io/sec-team:test-view created
$ kubectl apply -f production-namespace.yaml
namespace/production created
rolebinding.rbac.authorization.k8s.io/dev-team:production-view created
rolebinding.rbac.authorization.k8s.io/test-team:production-view created
rolebinding.rbac.authorization.k8s.io/ops-team:production-admin created
rolebinding.rbac.authorization.k8s.io/sec-team:production-view created
```

## Take Who-Can for a Spin

Once you have who-can installed, its usage is very straightforward.

```bash
$ kubectl kubectl who-can VERB (TYPE | TYPE/NAME | NONRESOURCEURL) [flags]
```

The typical set of verbs you may be interested in is `get`, `list`, `watch`, `create`, `update`, `patch`, and `delete`. There are a few others for specific resource types but, in general, you will be most interested in `get`, `create`, and `delete`.

The typical set of resource types you may be interested in includes `pods`, `deployments`, `services`, `persistentvolumeclaims`, `configmaps`, `secrets`, and more. Also, with the ever-expanding use of [`CustomResourceDefinitions`](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/), the list of resource types is never-ending.


## Who-Can Examples

Let's first ask "who can get pods in the development namespace?" Notice that all of the teams I created can get (see) pods. There are also quite a few others but most are system service accounts created during the cluster installation. One, tiller, isn't and we'll talk about it later.

```bash
$ kubectl who-can get pods -n development
ROLEBINDING                 NAMESPACE    SUBJECT    TYPE   SA-NAMESPACE
dev-team:development-edit   development  dev-team   Group
ops-team:development-admin  development  ops-team   Group
sec-team:development-view   development  sec-team   Group
test-team:development-view  development  test-team  Group

CLUSTERROLEBINDING                                    SUBJECT                             TYPE            SA-NAMESPACE
cluster-admin                                         system:masters                      Group
compose                                               compose                             ServiceAccount  kube-system
compose-auth-view                                     compose                             ServiceAccount  kube-system
system:controller:clusterrole-aggregation-controller  clusterrole-aggregation-controller  ServiceAccount  kube-system
system:controller:deployment-controller               deployment-controller               ServiceAccount  kube-system
system:controller:endpoint-controller                 endpoint-controller                 ServiceAccount  kube-system
system:controller:generic-garbage-collector           generic-garbage-collector           ServiceAccount  kube-system
system:controller:namespace-controller                namespace-controller                ServiceAccount  kube-system
system:controller:persistent-volume-binder            persistent-volume-binder            ServiceAccount  kube-system
system:controller:pvc-protection-controller           pvc-protection-controller           ServiceAccount  kube-system
system:controller:statefulset-controller              statefulset-controller              ServiceAccount  kube-system
system:kube-scheduler                                 system:kube-scheduler               User
tiller                                                tiller                              ServiceAccount  kube-system
ucp-kube-system:cni-plugin:cluster-admin              cni-plugin                          ServiceAccount  kube-system
ucp-kube-system:kube-dns:cluster-admin                kube-dns                            ServiceAccount  kube-system
ucp-kube-system:ucp-metrics:cluster-admin             ucp-metrics                         ServiceAccount  kube-system
```

Now let's ask "who can create pods in the development namespace?" Here we see that only our development and operations teams can create pods there. And the list of system service accounts is shorter but tiller is still there.

```bash
$ kubectl who-can create pods -n development
ROLEBINDING                 NAMESPACE    SUBJECT   TYPE   SA-NAMESPACE
dev-team:development-edit   development  dev-team  Group
ops-team:development-admin  development  ops-team  Group

CLUSTERROLEBINDING                                    SUBJECT                             TYPE            SA-NAMESPACE
cluster-admin                                         system:masters                      Group
system:controller:clusterrole-aggregation-controller  clusterrole-aggregation-controller  ServiceAccount  kube-system
system:controller:daemon-set-controller               daemon-set-controller               ServiceAccount  kube-system
system:controller:job-controller                      job-controller                      ServiceAccount  kube-system
system:controller:persistent-volume-binder            persistent-volume-binder            ServiceAccount  kube-system
system:controller:replicaset-controller               replicaset-controller               ServiceAccount  kube-system
system:controller:replication-controller              replication-controller              ServiceAccount  kube-system
system:controller:statefulset-controller              statefulset-controller              ServiceAccount  kube-system
tiller                                                tiller                              ServiceAccount  kube-system
ucp-kube-system:cni-plugin:cluster-admin              cni-plugin                          ServiceAccount  kube-system
ucp-kube-system:kube-dns:cluster-admin                kube-dns                            ServiceAccount  kube-system
ucp-kube-system:ucp-metrics:cluster-admin             ucp-metrics                         ServiceAccount  kube-system
```

Next, we'll ask "who can update anything in the development namespace?" Notice that our development can't just update anything they want in the development namespace with the edit role. For example, they can't update a `RoleBinding`. We don't want them to be able to change their own permissions. Yet, tiller is there again.

```bash
$ kubectl who-can update '*' -n development
No subjects found with permissions to update * assigned through RoleBindings

CLUSTERROLEBINDING                                    SUBJECT                             TYPE            SA-NAMESPACE
cluster-admin                                         system:masters                      Group
system:controller:clusterrole-aggregation-controller  clusterrole-aggregation-controller  ServiceAccount  kube-system
system:controller:generic-garbage-collector           generic-garbage-collector           ServiceAccount  kube-system
tiller                                                tiller                              ServiceAccount  kube-system
ucp-kube-system:cni-plugin:cluster-admin              cni-plugin                          ServiceAccount  kube-system
ucp-kube-system:kube-dns:cluster-admin                kube-dns                            ServiceAccount  kube-system
ucp-kube-system:ucp-metrics:cluster-admin             ucp-metrics                         ServiceAccount  kube-system
```

Let's talk about that tiller service account. The tiller service account is used by Helm to manage resources in a Kubernetes cluster. However, unless you explicitly limit its capabilities, by default the tiller account can do anything with any resource in any namespace. If you need to use helm, you need to implement RBAC for tiller to limit your security exposure. (Or, you could just wait for Helm 3 which doesn't require tiller.)

Next, let's look at the other namespaces. "Who can create services in the test namespace?" As you'd expect, only the test and operations teams can.

```bash
$ kubectl who-can create services -n test
ROLEBINDING          NAMESPACE  SUBJECT    TYPE   SA-NAMESPACE
ops-team:test-admin  test       ops-team   Group
test-team:test-edit  test       test-team  Group

CLUSTERROLEBINDING                                    SUBJECT                             TYPE            SA-NAMESPACE
cluster-admin                                         system:masters                      Group
system:controller:clusterrole-aggregation-controller  clusterrole-aggregation-controller  ServiceAccount  kube-system
system:controller:persistent-volume-binder            persistent-volume-binder            ServiceAccount  kube-system
tiller                                                tiller                              ServiceAccount  kube-system
ucp-kube-system:cni-plugin:cluster-admin              cni-plugin                          ServiceAccount  kube-system
ucp-kube-system:kube-dns:cluster-admin                kube-dns                            ServiceAccount  kube-system
ucp-kube-system:ucp-metrics:cluster-admin             ucp-metrics                         ServiceAccount  kube-system
```

Finally, "who can delete services in the production namespace?" And, only the operations team can.

```bash
$ kubectl who-can delete services -n production
ROLEBINDING                NAMESPACE   SUBJECT   TYPE   SA-NAMESPACE
ops-team:production-admin  production  ops-team  Group

CLUSTERROLEBINDING                                    SUBJECT                             TYPE            SA-NAMESPACE
cluster-admin                                         system:masters                      Group
system:controller:clusterrole-aggregation-controller  clusterrole-aggregation-controller  ServiceAccount  kube-system
system:controller:generic-garbage-collector           generic-garbage-collector           ServiceAccount  kube-system
system:controller:namespace-controller                namespace-controller                ServiceAccount  kube-system
system:controller:persistent-volume-binder            persistent-volume-binder            ServiceAccount  kube-system
tiller                                                tiller                              ServiceAccount  kube-system
ucp-kube-system:cni-plugin:cluster-admin              cni-plugin                          ServiceAccount  kube-system
ucp-kube-system:kube-dns:cluster-admin                kube-dns                            ServiceAccount  kube-system
ucp-kube-system:ucp-metrics:cluster-admin             ucp-metrics                         ServiceAccount  kube-system
```

## Summary

The who-can kubectl plugin from Aqua Security is a really useful utility for your Kubernetes toolbelt. Setting up role-based access controller for your Kubernetes cluster is extremely important but, also, different for each user. If you want or need help, Capstone IT is a Docker Premier Consulting Partner as well as being an Azure Gold and AWS Select partner. If you are interested in finding out more and getting help with your Container, Cloud and DevOps transformation, please [Contact Us](https://capstonec.com/contact-us/).

Ken Rider
Solutions Architect
Capstone IT