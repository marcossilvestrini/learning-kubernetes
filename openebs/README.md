# Openebs

Project for test OpenEBS in Kubernetes Cluster

## Getting started

## OpenEBS LocalPV Provisioner

### Install Dynamic-LocalPV-Provisioner on Rancher v2/RKE

#### About user in RKE2

<https://github.com/openebs/dynamic-localpv-provisioner/blob/develop/docs/installation/platforms/rancher.md>

#### Helm Charts

<https://github.com/openebs/charts/tree/main/charts/openebs>

#### User guide for localpv

<https://github.com/openebs/dynamic-localpv-provisioner/blob/develop/docs/quickstart.md>
<https://openebs.github.io/dynamic-localpv-provisioner>
<https://github.com/openebs/dynamic-localpv-provisioner/blob/develop/deploy/helm/charts/README.md>


#### Storage Class hostpath

Install using Helm chart

```sh
helm repo add openebs-localpv https://openebs.github.io/dynamic-localpv-provisioner
helm repo update
helm install [RELEASE_NAME] openebs-localpv/localpv-provisioner --namespace [NAMESPACE] --create-namespace
```

Install OpenEBS Dynamic LocalPV Provisioner with a custom hostpath directory.

```sh
helm install openebs-localpv openebs-localpv/localpv-provisioner --namespace openebs-localpv --create-namespace \
    --set localprovisioner.basePath=\var\k8s\storage\openebs
```

Install with custom values.yaml

```sh
helm upgrade --install openebs-localpv openebs-localpv/localpv-provisioner --namespace openebs-localpv --create-namespace \
    -f charts/localpv-provisioner/values.yaml \
    --set localprovisioner.basePath=\var\k8s\storage\openebs
```

Install using operator

```sh
kubectl apply -f https://openebs.github.io/charts/openebs-operator-lite.yaml -f https://openebs.github.io/charts/openebs-lite-sc.yaml
```

List resources

```sh
kubectl get pods -n openebs-localpv
```

list the blockdevices attached to the Kubernetes cluster nodes.

```sh
kubectl get bd -n openebs-localpv
```

### Provisioning LocalPV Hostpath Persistent Volume

Create StorageClass

```yaml
#This is a custom StorageClass template
# Uncomment config options as desired
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: custom-hostpath
  annotations:
    #Use this annotation to set this StorageClass by default
    # storageclass.kubernetes.io/is-default-class: true
    openebs.io/cas-type: local
    cas.openebs.io/config: |
      - name: StorageType
        value: "hostpath"
     #Use this to set a custom
     # hostpath directory
     #- name: BasePath
     #  value: "/var/openebs/local"
provisioner: openebs.io/local
reclaimPolicy: Delete
#It is necessary to have volumeBindingMode as WaitForFirstConsumer
volumeBindingMode: WaitForFirstConsumer
#Match labels in allowedTopologies to select nodes for volume provisioning
# allowedTopologies:
# - matchLabelExpressions:
#   - key: kubernetes.io/hostname
#     values:
#     - worker-1
#     - worker-2
```

Create a PVC with the StorageClass.

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: localpv-vol
spec:
  #Change this name if you are using a custom StorageClass
  storageClassName: openebs-hostpath
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      #Set capacity here
      storage: 5Gi
```

Mount the volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
  - command:
       - sh
       - -c
       - 'date >> /mnt/data/date.txt; hostname >> /mnt/data/hostname.txt; sync; sleep 5; sync; tail -f /dev/null;'
    image: busybox
    name: busybox
    volumeMounts:
    - mountPath: /mnt/data
      name: demo-vol
  volumes:
  - name: demo-vol
    persistentVolumeClaim:
      claimName: localpv-vol
```

## Authors and acknowledgment

[Official Docs](https://openebs.io/docs)
[User Guide Instalation](<https://openebs.io/docs/user-guides/installation>)
[Install Guide Dynamic Localpv Provisioner](https://openebs.github.io/dynamic-localpv-provisioner/)
[Mayastor Introduction](<https://mayastor.gitbook.io/introduction/>)
[Doc Performance Test](<https://magazine.atlassian.net/wiki/spaces/CLOUD/pages/3273752846/Storage+Relat+rio+de)+Performance>)
[Workload for Performance Test](<https://github.com/yasker/kbench>)

## License

 MIT License
