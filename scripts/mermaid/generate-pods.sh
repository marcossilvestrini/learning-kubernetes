#!/bin/bash

# Nome do arquivo README.md
README_FILE="README.md"

# Limpa o arquivo README.md existente
> "$README_FILE"

# Lista todos os namespaces no cluster Kubernetes
NAMESPACE_LIST=$(kubectl get namespaces -o json | jq -r '.items[].metadata.name')

# Loop pelos namespaces
for NAMESPACE in $NAMESPACE_LIST; do
  echo "### Namespace: $NAMESPACE" >> "$README_FILE"
  
  # Lista todos os pods no namespace atual
  POD_LIST=$(kubectl get pods -n "$NAMESPACE" -o json | jq -r '.items[].metadata.name')

  # Cria um diagrama Mermaid.js para os pods no namespace
  echo '```mermaid' >> "$README_FILE"
  echo 'graph TD;' >> "$README_FILE"

  for POD in $POD_LIST; do
    echo "  subgraph $NAMESPACE" >> "$README_FILE"
    echo "    style $NAMESPACE fill:#f9f,stroke:#333,stroke-width:4px;" >> "$README_FILE"
    echo "    $NAMESPACE/$POD" >> "$README_FILE"
    echo "  end" >> "$README_FILE"
  done

  echo '```' >> "$README_FILE"
done
