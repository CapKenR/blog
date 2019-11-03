
```bash
$ helm version
version.BuildInfo{Version:"v3.0.0-rc.1", GitCommit:"ee77ae3d40fd599445ebd99b8fc04e2c86ca366c", GitTreeState:"clean", GoVersion:"go1.13.3"}
```

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

