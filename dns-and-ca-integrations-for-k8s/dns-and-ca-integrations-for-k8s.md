# DNS and CA Integrations for Kubernetes

One of the challenges with demonstrating what you have done in Kubernetes is directing others to your application in a secure manner. This typically involves you having to create a DNS entry and requesting a certificate. Two projects, [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) and [cert-manager](https://cert-manager.io/), respectively, are making it much easier to automate this process and hide the complexities from developers. Both projects are under active development (with commits in the last few hours or days) and a lot of interest (thousands of stars on GitHub).

In the post that follows we'll create a Kubernetes cluster, add an ingress controller, and deploy our application. Then we'll deploy ExternalDNS and cert-manager in our cluster. Finally, we'll show how they can be used to give end users secure access to our application.

## Create a Kubernetes Cluster

To create our Kubernetes cluster, we will VMware's [Tanzu Kubernetes Grid](https://tanzu.vmware.com/kubernetes-grid) or TKG. TKG uses [Cluster API](https://github.com/kubernetes-sigs/cluster-api) to manage the lifecycle of Kubernetes clusters. In our case, we have a management cluster already running in AWS. We'll use it to create our workload cluster. The default dev plan creates a cluster with one control plan node and one worker node (as well as a bastion host for accessing them, if necessary). We'll modify this plan to have it create two worker nodes instead of one. We then retrieve the credentials for administering the cluster and see what has been built.

```bash
$ tkg create cluster demo-cluster --plan=dev --worker-machine-count 2
$ tkg get clusters
 NAME                 NAMESPACE  STATUS   CONTROLPLANE  WORKERS  KUBERNETES        ROLES
 demo-cluster         default    running  1/1           2/2      v1.19.3+vmware.1  <none>
$ tkg get credentials demo-cluster
Credentials of workload cluster 'demo-cluster' have been saved
You can now access the cluster by running 'kubectl config use-context demo-cluster-admin@demo-cluster'
$ kubectl config use-context demo-cluster-admin@demo-cluster
Switched to context "demo-cluster-admin@demo-cluster".
$ kubectl get nodes
NAME                                       STATUS   ROLES    AGE    VERSION
ip-10-0-1-235.us-west-2.compute.internal   Ready    <none>   119m   v1.19.3+vmware.1
ip-10-0-1-239.us-west-2.compute.internal   Ready    <none>   126m   v1.19.3+vmware.1
ip-10-0-1-96.us-west-2.compute.internal    Ready    master   128m   v1.19.3+vmware.1
```

## Install an Ingress Controller

To give end users access to applications running in our Kubernetes cluster, we need to install an ingress controller. For this example, we are going to use the [Contour](https://github.com/projectcontour/contour) ingress controller. There are three options for install Contour, a deployment manifest, an operator, or a Helm chart. We'll use the Helm chart in this case but you may want to explore the other options. The operator is an alpha but bears watching as operators in general make lifecycle management of cluster add-ins easier.

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm install contour bitnami/contour
```

## Install an application

For this demonstration we're going to install a generic NGINX website. For this we'll create simple `Deployment` and `Service` manifests and apply them.

```yaml nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
```
```yaml nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
  type: ClusterIP
```

```bash
$ kubectl apply -f nginx-deployment.yaml
$ kubectl apply -f nginx-service.yaml
```

We now have our demo application running in our new Kubernetes cluster but there is no way for an end user to access it.

## Install ExternalDNS

The [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) project configures DNS servers with addresses for services exposed by a Kubernetes cluster. ExternalDNS supports a large variety of DNS servers from cloud providers like AWS, Azure, and Google to more domain centric providers like Infoblox, GoDaddy, and DNSimple. Check the GitHub repository for a complete list. In our case, we use Azure DNS to manage our lab.capstonec.net subdomain.

In order to use ExternalDNS, we need to create a JSON file with the details of an Azure service principal with contributor permissions for the resource group (capstonec.net in this case) which contains the (lab.capstonec.net) DNS Zone resource.

```json
{
  "tenantId": "12345678-9012-3456-7890-123456789012",
  "subscriptionId": "abcdefgh-ijkl-mnop-qrst-uvwxyzabcdef",
  "resourceGroup": "capstonec.net",
  "aadClientId": "01234abc-de56-ff78-abc1-234567890def",
  "aadClientSecret": "0VZBkxeCSOtDHGgEMftg"
}
```

And, create a Kubernetes secret, `azure-config-file`, from this JSON file in the external-dns namespace.

```bash
$ kubectl create namespace external-dns
$ kubectl -n external-dns create secret generic azure-config-file --from-file=azure.json
```

Next, we create a deployment manifest for external-dns which includes the details of DNS domain being managed and the service principal secret we created above. The manifest also includes the `ClusterRole` and `ClusterRoleBinding` which allows ExternalDNS to list changes to ingresses, services, etc.
```yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: external-dns
rules:
- apiGroups: [""]
  resources: ["services","endpoints","pods"]
  verbs: ["get","watch","list"]
- apiGroups: ["extensions","networking.k8s.io"]
  resources: ["ingresses"] 
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["list"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: k8s.gcr.io/external-dns/external-dns:v0.7.6
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=lab.capstonec.net
        - --provider=azure
        volumeMounts:
        - name: azure-config-file
          mountPath: /etc/kubernetes
          readOnly: true
      volumes:
      - name: azure-config-file
        secret:
          secretName: azure-config-file
```

Deploy external-dns.
```bash
$ kubectl -n external-dns apply -f external-dns.yaml
```

At this point, ExternalDNS is now listening for ingresses and services of type `LoadBalancer` and will create DNS CNAME entries which correspond to them.

## Install cert-manager
The [cert-manager](https://cert-manager.io/) project makes the process of requesting and renewing certificates easy for resources within a Kubernetes cluster.

## Create Ingress

```yaml nginx-ingress.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: nginx
  annotations:
    cert-manager.io/cluster-issuer: azuredns-cluster-issuer
spec:
  rules:
  - host: nginx.lab.capstonec.net
    http:
      paths:
      - backend:
          serviceName: nginx-svc
          servicePort: 80
        path: /
  tls:
  - hosts:
    - nginx.lab.capstonec.net
    secretName: nginx-ingress-certificate
```

```bash
$ kubectl apply -f nginx-ingress.yaml
```

## View NGINX Website
![nginx.lab.capstonec.net in your browser](nginx.lab.capstonec.net-in-browser.png)
