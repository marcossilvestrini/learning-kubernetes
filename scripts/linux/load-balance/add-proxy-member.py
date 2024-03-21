import requests
import json

# Parâmetros da solicitação
url = 'http://load-balance.skynet.com.br:5000/add_member'
upstream = 'rke2_backend'
server = '192.168.0.140'
port = 9345
max_fails = 3
fail_timeout = '6s'

# Dados a serem enviados para a API em formato JSON
data = {
    'upstream': upstream,
    'server': server,
    'port': port,
    'max_fails': max_fails,
    'fail_timeout': fail_timeout
}

# Faz a chamada POST para a API Flask
response = requests.post(url, json=data)

# Verifica a resposta da API
if response.status_code == 200:
    print("Membro adicionado com sucesso.")
elif response.status_code == 400:
    print("Erro: Dados ausentes na solicitação.")
else:
    print(f"Erro desconhecido: {response.status_code}")

# Imprime a resposta da API para depuração (opcional)
print(response.text)
