# What is Container Orchestration - Kubernetes Version?

In a previous post, [What is Container Orchestration?](https://capstonec.com/what-is-container-orchestration/), I explained container orchestration using some examples based on Docker Swarm. While Docker Swarm is undeniably easier to both use and explain, [Kubernetes](https://kubernetes.io/) is by far the most prevalent container orchestrator today. So, I'm going to go through the same examples from that previous post but, this time, use Kubernetes. One of the great things about [Docker Enterprise](https://www.docker.com/products/docker-enterprise) is it supports both Swarm and Kubernetes so I didn't have to change my infrastructure at all.

## Visualizing Orchestration

I used the [Docker Swarm Visualizer](https://github.com/dockersamples/docker-swarm-visualizer) in the videos of the last post to help you visualize what was happening. For visualizing Kubernetes, I tried Brendan Burns' [gcp-live-k8s-visualizer](https://github.com/brendandburns/gcp-live-k8s-visualizer) and [Weaveworks Scope](https://github.com/weaveworks/scope). I found the former doesn't tie in the nodes enough and the latter has too much for simple demos. However, Scope has a lot of capabilities I'd like to explore further so I used it in the videos below.

## Taints and Tolerations

With Swarm I used node labels to designate two of the worker nodes in my cluster as being in my private cloud and two in my public cloud. Then, when I created the Swarm service, I used constraints to only run the service (initially) in my private cloud. In Kubernetes, the (rough) equivalent to labels are taints and the (rough) equivalent to constraints are tolerations. There are a lot more uses for taints and tolerations. If you want to learn more about them, see [Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/) in the Kubernetes documentation.

In our case, we are going to taint two of our worker nodes with the key-value pair of `cloud=private` and the effect of `NoSchedule`. For the other two, we use the key-value pair of `cloud=public` and the same effect. In essence, this tells the scheduler to not schedule anything on that node unless it has toleration for the specified key-value pair.

```bash
$ kubectl taint nodes ip-172-30-14-227.us-east-2.compute.internal cloud=private:NoSchedule
$ kubectl taint nodes ip-172-30-14-227.us-east-2.compute.internal cloud=private:NoSchedule
$ kubectl taint nodes ip-172-30-23-45.us-east-2.compute.internal cloud=public:NoSchedule
$ kubectl taint nodes ip-172-30-23-45.us-east-2.compute.internal cloud=public:NoSchedule
```

## Demonstrate Deploying, Scaling, and Upgrading

Once again, we start by creating a service using the official NGINX 1.14 image. The service will have replicas running in my private cloud. We will accomplish this by applying the following resource configuration files, kens-deployment.yaml and kens-service.yaml. The first creates the replica set responsible for the pods with the NGINX containers and the second creates a load balancer service so we can access it.

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: kens-deployment
  labels:
    visualize: "true"
    run: nginx
spec:
  selector:
    matchLabels:
      app: kens-app
  replicas: 2
  template:
    metadata:
      labels:
        app: kens-app
        visualize: "true"
        run: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14
        ports:
        - containerPort: 80
      tolerations:
      - key: "cloud"
        operator: "Equal"
        value: "private"
        effect: "NoSchedule"
```

```bash
$ kubectl apply -f kens-deployment.yaml
```

```yaml
kind: Service
apiVersion: v1
metadata:
  name: kens-service
  labels:
    visualize: "true"
    run: nginx
spec:
  type: LoadBalancer
  selector:
    app: kens-app
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
```

```bash
$ kubectl apply -f kens-service.yaml
```

Notice the pods created are only running on the worker nodes with the `cloud=private` taint.

Next, we'll scale the replica set from 2 to 4 replicas. We'll do this by updating the number of replicas specified in kens-deployment.yaml and applying it.

```yaml
  replicas: 2
```

```bash
$ kubectl apply -f kens-deployment.yaml
```

We now have 4 pods running and they're all on the private cloud worker nodes.

In my previous post, to allow the pods to run on both the private and public cloud worker nodes, we removed the private cloud constraint. However, with taints, we need to add a toleration for the public cloud to the pod specification in the deployment specification.

```yaml
      tolerations:
      - key: "cloud"
        operator: "Equal"
        value: "private"
        effect: "NoSchedule"
      - key: "cloud"
        operator: "Equal"
        value: "public"
        effect: "NoSchedule"
```

```bash
$ kubectl apply -f kens-deployment.yaml
```

This leads to a difference between Swarm and Kubernetes orchestration. When we took the equivalent action in Swarm, the scheduler, essentially, did nothing with the running containers. Since we removed a constraint from the service and didn't change the container specification, the scheduler didn't have to do anything as the current state of the running containers matched the desired state. In the Kubernetes case, we're making a change to the pod specification so the current state of the running pods doesn't match the desired state so the scheduler creates a new replica set and removes the previous one. As a result, we end up with pods running on both the private and public cloud worker nodes. In the Swarm example, we had to scale up the number of replicas to make that happen.

Finally, let's upgrade NGINX from 1.14 to 1.15. Again, we update the image tag in the pod specification of the deployment and apply it.

```yaml
    spec:
      containers:
      - name: nginx
        image: nginx:1.15
```

```bash
$ kubectl apply -f kens-deployment.yaml
```

## Demonstrate Failures

We'll start by demonstrating an all to typical upgrade failure scenario. As with Swarm, Kubernetes has quite a few options for detecting upgrade failures and automatically rolling back to the previous version. In this case, we're going to assume the upgrade succeeded but we found a problem post-upgrade. There are still several options available to us. You could use the `kubectl rollout` feature for deployments. (See [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) in the Kubernetes documentation.) However, we're a big believer in our current state matching our desired state along with matching what we have under source control. So, we'll update the deployment specification with an old image tag and apply it. (Or, maybe, we'll revert the change in our source and our CI/CD pipeline will apply it for us.) In any case, we'll see a rolling update to the pods.

Now, we'll demonstrate the failure of a container by deleting a pod. You will see the scheduler notices almost immediately that the current state, i.e. 3 pods, doesn't match the desired state, i.e. 4 pods, so it starts another one.

To simulate a server failure, I'm going to shutdown one of the worker nodes with the private cloud taint. Since my cluster is hosted in AWS, I'll use the AWS console to stop the instance. Again, the scheduler sees the current state doesn't match the desired state so it starts another pod on one of the available worker nodes.

Finally, to simulate a site or datacenter failure, I'll use the AWS console to stop the worker node with the private cloud taint. As before, another pod is started. More significantly, the last two scenarios can be viewed as disaster recovery. One site, our private cloud, is down and all the work has been migrated to our other site, our public cloud. This will work in any similar situation, i.e. two on-premises datacenters, an on-premises datacenter with a co-location facility, an on-premises datacenter with a public cloud (hybrid cloud), or two public clouds (multi-cloud).


## Resetting

We'll reset everything back to the way we started by:
1. Deleting the service and deployment we created; and
2. Removing the taints from the worker nodes.

```bash
$ kubectl delete -f kens-service.yaml
$ kubectl delete -f kens-deployment.yaml
$ kubectl taint nodes ip-172-30-14-227.us-east-2.compute.internal cloud:NoSchedule-
$ kubectl taint nodes ip-172-30-14-227.us-east-2.compute.internal cloud:NoSchedule-
$ kubectl taint nodes ip-172-30-23-45.us-east-2.compute.internal cloud:NoSchedule-
$ kubectl taint nodes ip-172-30-23-45.us-east-2.compute.internal cloud:NoSchedule-
```

## Summary

We've now seen how using Kubernetes as your container orchestrator makes it easier for an operations or DevOps team (or, in many cases today, a CI/CD pipeline) to manage applications in production. There are a lot more options and features available to you. If you want or need help, Capstone IT is a Docker Premier Consulting Partner as well as being an Azure Gold and AWS Select partner. If you are interested in finding out more and getting help with your Container, Cloud and DevOps transformation, please [Contact Us](https://capstonec.com/contact-us/).

Ken Rider
Solutions Architect
Capstone IT