#!/bin/bash

# Example use
# ./update-cert.sh --license-key "S-cdec00-b49907-e3850f-731f61" --subdomain "test" --ip "192.168.254.1" -c test-cert.pem -p test-key.pem

# Example crontab entry that runs 1st of every month at 3:00 AM
# 0 3 1 * * /opt/ghserver/update-cert.sh -k "S-131699-a20efd-68e066-33506e" -s "fccc-test" > /opt/ghserver/update-cert.log 2>&1

# Default values
CERT_PATH="/opt/ghserver/certs/cert.pem"
KEY_PATH="/opt/ghserver/certs/key.pem"
LICENSE_KEY=""
PUBLIC_IP=""
SUBDOMAIN=""
LICENSE_SERVER="https://update-public.goldenhelix.com/update"
#LICENSE_SERVER="https://update-testing.goldenhelix.com/update"

# Function to show usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -k, --license-key KEY    License key (required)"
    echo "  -i, --ip IP             IP address (defaults to auto-detect)"
    echo "  -s, --subdomain NAME    Subdomain name (required)"
    echo "  -c, --cert-path PATH    Path to save certificate (default: $CERT_PATH)"
    echo "  -p, --key-path PATH     Path to save private key (default: $KEY_PATH)"
    echo "  -h, --help             Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--license-key)
            LICENSE_KEY="$2"
            shift 2
            ;;
        -i|--ip)
            PUBLIC_IP="$2"
            shift 2
            ;;
        -s|--subdomain)
            SUBDOMAIN="$2"
            shift 2
            ;;
        -c|--cert-path)
            CERT_PATH="$2"
            shift 2
            ;;
        -p|--key-path)
            KEY_PATH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$LICENSE_KEY" ]; then
    echo "Error: License key is required"
    usage
fi

if [ -z "$SUBDOMAIN" ]; then
    echo "Error: Subdomain is required"
    usage
fi

# Auto-detect IP if not provided
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(curl -s https://api.ipify.org)
    if [ $? -ne 0 ]; then
        echo "Error: Could not auto-detect IP address"
        exit 1
    fi
fi

# Create directories if they don't exist
mkdir -p "$(dirname "$CERT_PATH")"
mkdir -p "$(dirname "$KEY_PATH")"

# Request certificate
response=$(curl -s -X POST "$LICENSE_SERVER/request_cert/" \
     -H "Content-Type: application/json" \
     -d "{\"license_key\": \"$LICENSE_KEY\", \"ip_address\": \"$PUBLIC_IP\", \"subdomain\": \"$SUBDOMAIN\"}")

# Check if curl was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to license server"
    exit 1
fi

# Check if we got a valid JSON response
if ! echo "$response" | jq . >/dev/null 2>&1; then
    echo "Error: Invalid response from server"
    echo "Response: $response"
    exit 1
fi

# Check if .certificate exists in the response
if echo "$response" | jq -e '.certificate' > /dev/null; then
  echo "$response" | jq -r '.certificate' > "$CERT_PATH"
  echo "$response" | jq -r '.private_key' > "$KEY_PATH"
else
  echo "Error: .certificate not found in the response"
  echo "$response"
  exit 1
fi

# Set appropriate permissions
chmod 644 "$CERT_PATH"
chmod 600 "$KEY_PATH"

# Reload Caddy if files were updated successfully
if [ $? -eq 0 ]; then
    cd /opt/ghserver
    docker compose restart web
    echo "restart admin-console" > configs/services/service-command
fi

echo "Certificate and key files have been updated:"
echo "Certificate: $CERT_PATH"
echo "Private key: $KEY_PATH"
