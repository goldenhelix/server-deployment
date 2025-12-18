#!/bin/bash
set -euo pipefail

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Check if domain name is provided
if [ $# -lt 1 ]; then
  echo "Error: Domain name must be provided."
  echo "Usage: $0 <domain_name>"
  exit 1
fi

domain_name=$1

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# Get the public IP of the server
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

echo "Waiting for server at https://${domain_name} to respond..."

# Timeout in seconds
TIMEOUT=30
START_TIME=$(date +%s)
SUCCESS=false

while true; do
    # Calculate elapsed time
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    # Try to curl the endpoint from the server itself and capture the HTTP status code
    # Allow for errors in SSH/curl
    set +e
    HTTP_CODE=$(ssh -q -o ConnectTimeout=5 -o "StrictHostKeyChecking=no" \
        -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
        "$ADMIN_USER"@"$public_ip" \
        "curl -s -o /dev/null -w '%{http_code}' --max-time 5 --insecure 'https://${domain_name}/auth/api/authenticationMethod' 2>/dev/null" 2>/dev/null || echo "000")
    set -e
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "Server is responding with HTTP 200!"
        SUCCESS=true
        break
    fi
    
    # Check if we've exceeded the timeout
    if [ $ELAPSED -ge $TIMEOUT ]; then
        break
    fi
    
    # Wait a bit before retrying
    sleep 2
done

if [ "$SUCCESS" = false ]; then
    echo "WARNING: Server did not respond with HTTP 200 within ${TIMEOUT} seconds"
    echo "Last HTTP status code received: ${HTTP_CODE:-unknown}"
    echo "You may need to wait longer for the server to fully start up"
    exit 1
fi

