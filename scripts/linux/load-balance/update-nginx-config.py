import requests
import sys
import os

def main():
    if len(sys.argv) != 6:
        print("Use: python script.py upstream server port max_fails fail_timeout")
        sys.exit(1)

    upstream = sys.argv[1]
    server = sys.argv[2]
    port = sys.argv[3]
    max_fails = sys.argv[4]
    fail_timeout = sys.argv[5]

    api_url = "http://load-balance.skynet.com.br:5000/update_nginx_config"

    data = {
        "upstream": upstream,
        "server": server,
        "port": port,
        "max_fails": max_fails,
        "fail_timeout": fail_timeout
    }

    try:
        response = requests.post(api_url, json=data)
        if response.status_code == 200:
            print("Member add with success in upstream.")
        else:
            print(f"Error in add member: {response.status_code}")
    except Exception as e:
        print(f"Connection API error: {str(e)}")

if __name__ == '__main__':
    main()

# Use: 
# pip install requests && python3 scripts/load-balance/update-nginx-config.py upstream_name server_address port max_fails fail_timeout
# pip install requests && python3 scripts/load-balance/update-nginx-config.py rke2_backend 192.168.0.141 9345 3 6s