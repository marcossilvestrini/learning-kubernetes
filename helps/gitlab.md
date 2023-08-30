# Helps Gitlab

## Deploy kubernetes operator

<https://docs.gitlab.com/operator/installation.html>

```sh
GL_OPERATOR_VERSION="0.22.1" # https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/releases
PLATFORM=kubernetes # or "openshift"
kubectl create namespace gitlab-system
kubectl apply -f https://gitlab.com/api/v4/projects/18899486/packages/generic/gitlab-operator/${GL_OPERATOR_VERSION}/gitlab-operator-${PLATFORM}-${GL_OPERATOR_VERSION}.yaml
kubectl -n gitlab-system apply -f configs/gitlab/gitlab.yaml
```

## Deploy gitlab with helm

kubectl create namespace gitlab
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --set certmanager.installCRDs=false \
  --namespace gitlab \
  --timeout 600s \
  --set global.hosts.domain=skynet.com.br \
  --set global.edition=ce \
  --set certmanager-issuer.email=marcos.silvestrini@gmail.com \
  --set postgresql.image.tag=13.6.0 \
  --set gitlab.migrations.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ce \
  --set gitlab.sidekiq.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce \
  --set gitlab.unicorn.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ce \
  --set gitlab.unicorn.workhorse.image=registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce