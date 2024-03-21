#!/bin/bash

# Set language/locale and encoding
export LANG=C

# Set workdir
WORKDIR="/home/vagrant"
cd $WORKDIR || exit

# Diretório onde o backup será armazenado
BACKUP_DIR="configs/gitlab"
BACKUP_FILE="$BACKUP_DIR/gitlab_secrets_backup.tar.gz"
NAMESPACE="gitlab" # O namespace onde as secrets estão localizadas

# Função para criar o namespace se não existir
create_namespace_if_not_exists() {
  if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Namespace $NAMESPACE não existe. Criando..."
    kubectl create namespace "$NAMESPACE"
  fi
}

# Função para restaurar secrets do tipo "Opaque" apenas se elas não existirem
restore_opaque_secrets() {
  tar -zxvf "$BACKUP_FILE" -C "$BACKUP_DIR"
  for file in "$BACKUP_DIR"/*.yaml; do
    secret_name=$(basename "$file" .yaml)
    # Verifica se a secret já existe
    if ! kubectl get secret "$secret_name" -n "$NAMESPACE" &> /dev/null; then
      kubectl apply -f "$file" -n "$NAMESPACE"
      echo "Secret $secret_name restaurada com sucesso."
    else
      echo "Secret $secret_name já existe. Pulando a restauração."
    fi
  done
}

# Verifica se o arquivo de backup existe
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Arquivo de backup não encontrado: $BACKUP_FILE"
  exit 1
fi

# Cria um diretório temporário para extrair os arquivos
BACKUP_DIR=$(mktemp -d)

# Cria o namespace se não existir
create_namespace_if_not_exists

# Restaura secrets do tipo "Opaque" apenas se elas não existirem e descompacta os arquivos
restore_opaque_secrets

# Limpa o diretório temporário
rm -rf "$BACKUP_DIR"

echo "Restauração das secrets do tipo 'Opaque' concluída."