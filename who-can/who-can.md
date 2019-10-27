# Who Can...?

Managing a Kubernetes cluster with one user is easy. Once you go beyond one user, you need to start using Role-Based Access Control (RBAC). I've delved into this topic several times in the past with posts on how to [Create a Kubernetes User Sandbox in Docker Enterprise](https://capstonec.com/create-a-user-k8s-sandbox-in-docker-ee/) and [Functional Kubernetes Namespaces in Docker Enterprise](https://capstonec.com/dev-test-and-prod-k8s-namespaces-in-docker-ee/). But, once you get beyond a couple of users and/or teams and a few namespaces for them, it quickly becomes difficult to figure out who can do what and where. And, as time goes on and more and more people have a hand in setting up your RBAC, it can get even more confusing. You can and should have your RBAC resource definitions in source control but it's not easy to read and is hard to visualize. Enter the open source [who-can](https://github.com/aquasecurity/kubectl-who-can) kubectl plugin from the folks at [Aqua Security](https://www.aquasec.com/). It gives you the ability to show who (subjects) can do what (verbs) where (namespaces).

## Install the Krew Plugin Manager

The who-can plugin for kubectl requires the krew plugin manager. If you don't already have krew installed, the instructions for installing it can be found on its GitHub repository, https://github.com/kubernetes-sigs/krew/. To verify it's installed correctly, you can get a list of available plugins from kubectl.

```bash
$ kubectl plugin list
```

## Install the Who-Can Plugin

Once you have the krew plugin manager for kubectl, installing the who-can plugin is easy.

```bash
$ kubectl krew install who-can
```

Once you have it installed, its usage is very straightforward.

```bash
$ kubectl kubectl who-can VERB (TYPE | TYPE/NAME | NONRESOURCEURL) [flags]
```

## Take Who-Can for a Spin

Now that we have who-can installed, let's try it out. I have a Kubernetes cluster I built in Azure using [Docker Enterprise](https://www.docker.com/products/docker-enterprise). I have 3 (non-default) namespaces for development, test and production. I also have teams for development, test, operations, and security which I've created as a cluster admin user. I've defined a set of RoleBindings for each along the lines of those I used in my blog post on functional namespaces but taking advantage of the default ClusterRoles created with the Docker Enterprise installation.

The typical set of verbs you may be interested in is `get`, `list`, `watch`, `create`, `update`, `patch`, and `delete`. There are a few others for specific resource types but, in general, you will be most interested in `get`, `create`, and `delete`.

The typical set of resource types you may be interested includes `pods`, `deployments`, `services`, and more. In addition, with the ever expanding use of [`CustomResourceDefinitions`](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/), the list of resources is never ending.

