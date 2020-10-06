* Download kubeconfig-tanzu.yml
* Generate API token
* Download tmc
* `tmc login`
```bash
ken:Downloads$ tmc login
i To fetch an API token visit https://console.cloud.vmware.com/csp/gateway/portal/#/user/tokens and select an appropriate organization and create with TMC service roles
? API Token ****************************************************************
? Login context name aws-tanzu
? Select default log level info
? Select default credential aws-cluster-credential
? Select default region us-east-2
? Select default AWS SSH key tanzu-mission-control
√ Successfully created context aws-tanzu, to manage your contexts run `tmc system context -h`
```
* `export KUBECONFIG=$PWD/kubeconfig-tanzu.yml`
```bash
ken:Downloads$ istioctl manifest apply --set profile=demo
Detected that your cluster does not support third party JWT authentication. Falling back to less secure first party JWT. See https://istio.io/docs/ops/best-practices/security/#configure-third-party-service-account-tokens for details.
- Applying manifest for component Base...
✔ Finished applying manifest for component Base.
- Applying manifest for component Pilot...
✔ Finished applying manifest for component Pilot.
  Waiting for resources to become ready...
  Waiting for resources to become ready...
  Waiting for resources to become ready...
  Waiting for resources to become ready...
  Waiting for resources to become ready...
- Applying manifest for component EgressGateways...
- Applying manifest for component IngressGateways...
- Applying manifest for component AddonComponents...
✔ Finished applying manifest for component EgressGateways.
✔ Finished applying manifest for component IngressGateways.
✔ Finished applying manifest for component AddonComponents.


✔ Installation complete
```

```bash
$ kubectl get deployments -n vmware-system-tmc
NAME                                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/agent-updater                 1/1     1            1           11m
deployment.apps/cluster-health-extension      1/1     1            1           9m49s
deployment.apps/extension-manager             1/1     1            1           11m
deployment.apps/extension-updater             1/1     1            1           11m
deployment.apps/gatekeeper-operator-manager   1/1     1            1           9m47s
deployment.apps/inspection-extension          1/1     1            1           9m45s
deployment.apps/intent-agent                  1/1     1            1           9m44s
deployment.apps/policy-sync-extension         1/1     1            1           9m44s
deployment.apps/policy-webhook                2/2     2            2           9m44s
deployment.apps/sync-agent                    1/1     1            1           9m38s
deployment.apps/tmc-observer                  1/1     1            1           9m43s
```

```bash
$ kubectl -n vmware-system-tmc logs policy-sync-extension-6465b5599b-v949n | grep "Starting Controller"
{"component":"controller","controller":"clusterpolicy-controller","level":"info","msg":"Starting Controller","time":"2020-05-18T17:27:04Z"}
{"component":"controller","controller":"policydefinition-controller","level":"info","msg":"Starting Controller","time":"2020-05-18T17:27:04Z"}
{"component":"controller","controller":"namespaceaccesspolicy-controller","level":"info","msg":"Starting Controller","time":"2020-05-18T17:27:04Z"}
{"component":"controller","controller":"managednamespace-controller","level":"info","msg":"Starting Controller","time":"2020-05-18T17:27:04Z"}
{"component":"controller","controller":"network-policy-controller","level":"info","msg":"Starting Controller","time":"2020-05-18T17:27:04Z"}
{"component":"controller","controller":"opapolicy-controller","level":"info","msg":"Starting Controller","time":"2020-05-18T17:27:04Z"}
```
