#!/bin/bash

# Nome do arquivo .env de entrada
input_file="security/.env"

# Nome do arquivo YAML de saída
output_file="security/secret-backstage.yaml"

# Verifica se o arquivo .env existe
if [ ! -f "$input_file" ]; then
  echo "File $input_file not found"
  exit 1
fi

# Abre o arquivo de saída para escrita
echo "Convert file .env to kubernetes secret yaml..."
echo "apiVersion: v1" > "$output_file"
echo "kind: Secret" >> "$output_file"
echo "metadata:" >> "$output_file"
echo "  name: backstage-secret" >> "$output_file"
echo "type: Opaque" >> "$output_file"
echo "data:" >> "$output_file"

# Lê o arquivo .env linha por linha e converte as variáveis, ignorando comentários
grep -vE '^\s*#|^\s*$' "$input_file" | while IFS= read -r line; do
  # Verifica se a linha contém "export" e remove, se presente
  line=$(echo "$line" | sed 's/^export //')
  
  # Extrai o nome e o valor da variável
  var_name=$(echo "$line" | cut -d'=' -f1)
  var_value=$(echo "$line" | cut -d'=' -f2)
  
  # Remove espaços em branco no valor e as aspas
  var_value=$(echo "$var_value" | tr -d ' ' | sed 's/"//g')
  
  # Converte o valor para base64
  var_base64=$(echo -n "$var_value" | base64 -w0)
  
  
  # Adiciona a variável ao arquivo YAML sem o "export"
  echo "  $var_name: \"$var_base64\"" >> "$output_file"
done

echo "File $output_file generate success."