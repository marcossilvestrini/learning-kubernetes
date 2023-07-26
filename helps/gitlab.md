# Helps Gitlab

## Deploy gitlab with helm

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=gitlab.skynet.com.br \
  --set global.edition=ce \
  --set global.hosts.externalIP=10.10.10.10 \
  --set certmanager-issuer.email=mr.durock01@gmail.com \
  --set postgresql.image.tag=13.6.0