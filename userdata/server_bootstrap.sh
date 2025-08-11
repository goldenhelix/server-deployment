#!/bin/bash
set -ex
echo "Starting Golden Helix Server Install"
START_TIME=$(date +%s)

# Detect cloud provider
# Check for Azure-specific metadata response
AZURE_RESPONSE=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" 2>/dev/null || echo "")
if [[ "$AZURE_RESPONSE" == *"compute"* ]] && [[ "$AZURE_RESPONSE" == *"network"* ]]; then
    CLOUD_PROVIDER="azure"
    PRIVATE_IP=$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2021-02-01&format=text")
# Check for AWS-specific metadata response
elif curl -s "http://169.254.169.254/latest/meta-data/ami-id" > /dev/null 2>&1; then
    CLOUD_PROVIDER="aws"
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
fi

echo "Detected cloud provider: $CLOUD_PROVIDER"

## Create Swap partition
fallocate -l ${swap_size}g /var/custom.swap
chmod 600 /var/custom.swap
mkswap /var/custom.swap
swapon /var/custom.swap
echo '/var/custom.swap swap swap defaults 0 0' | tee -a /etc/fstab

cd /tmp

if [ "$CLOUD_PROVIDER" = "aws" ]; then
    # Attempt to fix hang in wget that happens in some cases
    sleep 2

    # Get the current region from metadata service (using IMDSv2 token)
    AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
    

    # Install the SSM Agent using region-specific URL
    # https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-deb.html
    wget https://s3.$AWS_REGION.amazonaws.com/amazon-ssm-$AWS_REGION/latest/debian_amd64/amazon-ssm-agent.deb
    dpkg -i amazon-ssm-agent.deb
    systemctl status amazon-ssm-agent
fi

# Update package manager, upgrade packages, and install unattended-upgrades
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades curl xfsprogs

# Download and run the installer for Golden Helix Server
curl -o install.sh https://www.goldenhelix.com/Downloads/install.sh
# curl -o install.sh https://www.goldenhelix.com/Downloads/install-insiders.sh
chmod +x install.sh

# Set the hostname to the Private IP in /etc/hosts
echo "$PRIVATE_IP ${domain_name}" >> /etc/hosts

hostnamectl set-hostname "${domain_name}"

# PREPARE SYSTEM

# System dependencies
./install.sh -y install_dependencies 
# Create unprivileged ghuser, which is used to run rootless docker
./install.sh -y create_user 
# Install rootless docker under ghuser
./install.sh -y install_docker

# NAT SETUP
# The server acts as a NAT gateway to allow dynamic agents to have outbound internet access

# Install iptables-persistent non-interactively for NAT functionality
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

# Add NAT configuration AFTER Docker install (to avoid Docker iptables rules overwriting)
IFACE=$(ip route | grep default | awk '{print $5}')
echo "Using interface: $IFACE for NAT configuration..."
iptables -t nat -A POSTROUTING -o $IFACE -s ${private_subnet_cidr} -j MASQUERADE
iptables -P FORWARD ACCEPT
iptables -I FORWARD 1 -i $IFACE -s ${private_subnet_cidr} -j ACCEPT
iptables -I FORWARD 2 -o $IFACE -d ${private_subnet_cidr} -j ACCEPT
netfilter-persistent save
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p # Apply sysctl changes

# Set device name based on cloud provider
if [ "$CLOUD_PROVIDER" = "aws" ]; then
    DEVICE="/dev/xvdf"
else
    DEVICE="/dev/sdb"
fi

# Wait for the device to become available (timeout after 5 minutes)
timeout=300
while [ ! -b "$DEVICE" ] && [ $timeout -gt 0 ]; do
    echo "Waiting for $DEVICE to become available... ($timeout seconds remaining)"
    sleep 5
    timeout=$((timeout - 5))
done

if [ ! -b "$DEVICE" ]; then
    echo "Error: Timeout waiting for $DEVICE to become available"
    exit 1
fi

## Add second volume for workflows
mkfs.xfs "$DEVICE"
mkdir -p /opt
mount "$DEVICE" /opt
echo "$DEVICE /opt xfs defaults 0 2" >> /etc/fstab

# SERVER SETUP

# Log into the Golden Helix Docker registry
sudo -u ghuser -g ghuser -i /bin/bash -c 'docker login --username "${registry_user}" --password "${registry_pass}" registry.goldenhelix.com'

# Variables used by create_install
export domain_name="${domain_name}"
export email="${primary_email}"
export server_ip="$PRIVATE_IP"

# Use auto for public DNS servers to get LetsEncrypt certificates
# export cert_file=auto
# export cert_key=auto

# Generate self-signed certificates as ghuser under /opt/ghserver/certs
mkdir -p /opt/ghserver/certs
chown ghuser:ghuser -R /opt/ghserver
sudo -u ghuser -g ghuser -i /bin/bash <<EOF
cd /opt/ghserver
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=${domain_name}" \
    -keyout certs/key.pem \
    -out certs/cert.pem
EOF

export cert_type="custom"
export cert_file="/opt/ghserver/certs/cert.pem"
export cert_key="/opt/ghserver/certs/key.pem"

# Pulls the docker images, initializes the configs under /opt/ghserver, and starts the server
echo "Running installer"
./install.sh -y create_install

# Setup backup cron job
./install.sh -y setup_backup

# Clear the static /etc/motd content
echo "" > /etc/motd

# Create dynamic MOTD script
cat > /etc/update-motd.d/99-custom <<'EOF'
#!/bin/bash

# ANSI color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cat << 'MOTD'

Welcome to Golden Helix Server

Key Information:
---------------
- Service account: ghuser (no password, no sudo)
- Installation directory: /opt/ghserver
- Docker running as rootless under ghuser

Quick Commands:
--------------
sudo machinectl shell ghuser@.host         # Switch to service account
cd /opt/ghserver                           # Go to installation directory
docker compose ps                          # Review dokcer-compose services
docker compose logs -n 100 auth            # Review auth logs
systemctl --user list-units --type=service # List user services (including mounts)
systemctl --user restart ghserver.service  # Restart the server
journalctl --user -u ghserver.service      # Check server logs

Note: This is a production server. Please ensure all actions are authorized.

MOTD

EOF

# Make the script executable
chmod +x /etc/update-motd.d/99-custom

echo "Sleeping for 10 seconds to allow the server to start"
sleep 10 # Wait for the server to start

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo "Total setup duration: $DURATION seconds ($(($DURATION/60)) minutes)"
