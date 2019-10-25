# Who Can...?

Managing a Kubernetes cluster with one user is easy. Once you go beyond one user, you need to start using Role-Based Access Control (RBAC). I've delved into this topic several times in the past with posts on how to [Create a Kubernetes User Sandbox in Docker Enterprise](https://capstonec.com/create-a-user-k8s-sandbox-in-docker-ee/) and [Functional Kubernetes Namespaces in Docker Enterprise](https://capstonec.com/dev-test-and-prod-k8s-namespaces-in-docker-ee/). But, once you get beyond a couple of users and/or teams and a few namespaces for them, it quickly becomes difficult to figure out who can do what and where. And, as time goes on and more and more people have a hand in setting up your RBAC, it can get even more confusing. Enter the open source [who-can](https://github.com/aquasecurity/kubectl-who-can) kubectl plugin from the folks at [Aqua Security](https://www.aquasec.com/). It gives you the ability to show who (subjects) can do what (verbs) where (namespaces).

## Install the Krew Plugin Manager

## Install the Who-Can Plugin

## Take Who-Can for a Spin
