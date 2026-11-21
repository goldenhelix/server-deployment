#!/bin/bash
# Switch the server's email delivery from SMTP to SendGrid (HTTPS):
# copies configs/sendgrid.yaml to /opt/ghserver/configs/sendgrid.yaml and sets
# smtp_enabled: false / sendgrid_enabled: true in /opt/ghserver/config.yaml.

# Define TF as tofu or terraform based on the environment variable
if [ -f env.sh ]; then
  source env.sh
fi

# Determine Terraform directory based on provider
TF_DIR="tf_${CLOUD_PROVIDER:-aws}"

# SendGrid counts as configured only if configs/sendgrid.yaml exists, has
# non-whitespace content, and its active api_key is not the shipped placeholder.
# Auto-deploy writes an empty/whitespace-only file to mean "use SMTP".
# `--check` tests just that (exit 0 = configured) without touching the server;
# create_server.sh / continue.sh use it to pick SendGrid or SMTP.
SENDGRID_YAML=configs/sendgrid.yaml
sendgrid_configured() {
  [ -f "$SENDGRID_YAML" ] || return 1
  grep -q '[^[:space:]]' "$SENDGRID_YAML" || return 1
  ! grep -Eq "^[[:space:]]*api_key:[[:space:]]*[\"']?SG\.replace_with_your_api_key" "$SENDGRID_YAML"
}

if [ "$1" = "--check" ]; then
  sendgrid_configured
  exit $?
fi

# Refuse to switch over while unconfigured: that would turn off working SMTP
# delivery in favour of a SendGrid config that can't send.
if ! sendgrid_configured; then
  echo "$SENDGRID_YAML is missing, empty, or still has the placeholder api_key; edit it first." >&2
  exit 1
fi

echo "Transferring configs/sendgrid.yaml to the server..."
public_ip=$(cd "$TF_DIR" && $TF output -raw public_ip)

scp -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    configs/sendgrid.yaml "$ADMIN_USER"@"$public_ip":/tmp/sendgrid.yaml

# Move the file into place, disable SMTP, enable SendGrid (adding the key to
# config.yaml if this server's config predates it), then reload
remote_path="/opt/ghserver/configs/sendgrid.yaml"
ssh -q -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i ssh_key.pem \
    "$ADMIN_USER"@"$public_ip" "sudo mv /tmp/sendgrid.yaml $remote_path && \
    sudo chown ghuser:ghuser $remote_path && \
    sudo sed -i '/^smtp_enabled:/ s/true/false/' /opt/ghserver/config.yaml && \
    if sudo grep -q '^sendgrid_enabled:' /opt/ghserver/config.yaml; then \
        sudo sed -i '/^sendgrid_enabled:/ s/false/true/' /opt/ghserver/config.yaml; \
    else \
        echo 'sendgrid_enabled: true' | sudo tee -a /opt/ghserver/config.yaml > /dev/null; \
    fi && \
    sudo grep -E '^(smtp|sendgrid)_enabled:' /opt/ghserver/config.yaml && \
    sudo -u ghuser -g ghuser -i /bin/bash -c 'cd /opt/ghserver && ./ghadmin server-reload-auth && sleep 2s'"
