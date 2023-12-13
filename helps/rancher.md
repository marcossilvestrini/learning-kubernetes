
# Install single rke2 node

```sh
curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL=v1.24.14+rke2r1 sh -
systemctl enable --now rke2-server.service
export PATH="/var/lib/rancher/rke2/bin:$PATH"
```

# Set DNS

```sh
# /etc/hosts
10.173.228.135	rancher.local
10.173.228.135	control-plane.local
```

# Install Helm

## Install Helm

```sh
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Copy kubectl binary to the local user bin folder

```sh
cp /var/lib/rancher/rke2/bin/kubectl /usr/local/bin
```

# Deploy Rancher

## Add the Rancher Stable Helm Repo
```sh
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
```

## Install cert-manager
```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
```

## Create a namespace for Rancher

```sh
kubectl create namespace cattle-system
```

## Install Rancher using Helm

```sh
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.skynet.com.br \
  --set bootstrapPassword=Rancher@123456
```

## Output after deploy rancher

NAME: rancher
LAST DEPLOYED: Mon Jul 24 15:35:04 2023
NAMESPACE: cattle-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Rancher Server has been installed.

NOTE: Rancher may take several minutes to fully initialize. Please standby while Certificates are being issued, Containers are started and the Ingress rule comes up.

Check out our docs at https://rancher.com/docs/

If you provided your own bootstrap password during installation, browse to https://rancher.local to get started.

If this is the first time you installed Rancher, get started by running this command and clicking the URL it generates:

```sh
echo https://rancher.local/dashboard/?setup=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')
```

To get just the bootstrap password on its own, run:

```sh
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'
```

Happy Containering!

## Uninstall

<https://github.com/rancher/rancher-cleanup>