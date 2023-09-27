from flask import Flask, request, jsonify
import subprocess
import os

app = Flask(__name__)

@app.route('/update_nginx_config', methods=['POST'])
def update_nginx_config():
    data = request.json

    # Verifique se todos os campos necessários estão presentes nos dados JSON
    required_fields = ['upstream', 'server', 'port', 'max_fails', 'fail_timeout']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Missing field: {field}'}), 400

    # Input parameters
    upstream = data['upstream']
    server = data['server']
    port = data['port']
    max_fails = data['max_fails']
    fail_timeout = data['fail_timeout']

    # Check if the Nginx configuration file exists
    nginx_conf = "/etc/nginx/nginx.conf"  # Change the path as needed
    if not os.path.exists(nginx_conf):
        return jsonify({'error': f'Nginx configuration file not found: {nginx_conf}'}), 500

    # Check if the upstream exists in the configuration file
    grep_process = subprocess.run(["grep", "-q", f"upstream {upstream}", nginx_conf], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if grep_process.returncode != 0:
        return jsonify({'error': f'Upstream not found: {upstream}'}), 400

    # Check if the member already exists in the configuration file
    grep_process = subprocess.run(["grep", "-q", f"server {server}:{port} max_fails={max_fails} fail_timeout={fail_timeout};", nginx_conf], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if grep_process.returncode == 0:
        return jsonify({'error': 'The member already exists in the configuration file.'}), 400

    # Add the new member to the configuration file using sed
    sed_command = f'sed -i "/upstream {upstream} {{/a \        server {server}:{port} max_fails={max_fails} fail_timeout={fail_timeout};" {nginx_conf}'
    subprocess.run(sed_command, shell=True, check=True)

    # Reload Nginx to apply the changes
    reload_command = 'systemctl reload nginx'
    subprocess.run(reload_command, shell=True, check=True)

    return jsonify({'message': f'New member successfully added to upstream {upstream}.'}), 200

if __name__ == '__main__': 
    app.run(host='load-balance.skynet.com.br', port=5000)
    
# Use
# pip install flask && nohup python3 api/load-balance/api-update-nginx-config.py &
