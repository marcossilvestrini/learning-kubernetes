#!/bin/bash

# Set language/locale and encoding
export LANG=C

# Set workdir
WORKDIR="/home/vagrant"
cd $WORKDIR || exit

# Diretório onde o backup será armazenado
BACKUP_DIR="configs/gitlab"
#TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_FILE="$BACKUP_DIR/gitlab_secrets_backup.tar.gz"

# Namespace onde as secrets do GitLab estão localizadas
NAMESPACE="gitlab"

# Lista de nomes de secrets para backup
SECRETS=(
    gitlab-acme-key
    gitlab-gitaly-secret
    gitlab-gitlab-initial-root-password
    gitlab-gitlab-kas-secret
    gitlab-gitlab-runner-secret
    gitlab-gitlab-shell-host-keys
    gitlab-gitlab-shell-secret
    gitlab-gitlab-suggested-reviewers
    gitlab-gitlab-workhorse-secret
    gitlab-kas-private-api
    gitlab-kas-tls-tgsj5
    gitlab-minio-secret
    gitlab-minio-tls-7pzr9
    gitlab-postgresql-password
    gitlab-rails-secret
    gitlab-redis-secret
    gitlab-registry-httpsecret
    gitlab-registry-notification
    gitlab-registry-secret
    gitlab-registry-tls-m2qdl
    gitlab-zoekt-basicauth
)

# Verifica se o diretório de backup existe
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# Loop para fazer o backup de cada secret
for SECRET_NAME in "${SECRETS[@]}"; do
    kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/$SECRET_NAME.yaml"
done

# Compacta os arquivos em um único arquivo de backup
tar -czvf "$BACKUP_FILE" -C "$BACKUP_DIR" .

# Limpa os arquivos temporários
rm -rf "$BACKUP_DIR"/*.yaml

echo "Backup das secrets do GitLab concluído em $BACKUP_FILE"
