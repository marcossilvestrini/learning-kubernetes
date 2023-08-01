# Helps Gitlab

## Deploy kubernetes operator

<https://docs.gitlab.com/operator/installation.html>

## Deploy gitlab with helm

kubectl create namespace gitlab

helm repo add gitlab https://charts.gitlab.io/
helm repo update
kubectl create namespace gitlab

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --set certmanager.installCRDs=false \
  --namespace gitlab \
  --timeout 600s \
  --set global.hosts.domain=gitlab.local \
  --set global.edition=ce \
  --set global.hosts.externalIP=209.127.140.10 \
  --set certmanager-issuer.email=marcos.silvestrini@gmail.com \
  --set postgresql.image.tag=13.6.0 \
  --set gitlab.migrations.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ce \
  --set gitlab.sidekiq.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce \
  --set gitlab.unicorn.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ce \
  --set gitlab.unicorn.workhorse.image=registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce