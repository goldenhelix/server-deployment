# Cloud provider (default: AWS)
CLOUD_PROVIDER="aws"  # Change to "azure" for Azure deployments

# Terraform binary location
TF=tofu

# License key for the server
LICENSE_KEY=S-000000-000000-000000-000000

# Server name
SERVER_NAME="Institution Server"

# Workspace details
WORKSPACE="workspace"
WORKSPACE_NAME="Workspace"

# Timezone and locale settings
TIMEZONE="America/New_York"
LOCALE="en_US.UTF-8"

# Assembly version
ASSEMBLY="hg38"

# Change to true to enable SAML (based on configs/saml.yaml)
SETUP_SAML=true

# Optional Sentieon license file 
# SENTIEON_LICENSE_FILE="configs/Institution.varseq.lic"

# Optional SSL files
# SSL_CERT="configs/cert.crt"
# SSL_KEY="configs/cert.key"

# Optional DxFuse API key and project name
# DX_MOUNT_NAME="DXCloudStorage"
# DX_API_TOKEN="api_token"
# DX_PROJECT_NAME="project_name"

# Optional BaseSpace mount details
# BASESPACE_MOUNT_NAME="BaseSpace"
# BASESPACE_API_TOKEN="api_token"

# Optional Azure Blob Storage details
# AZURE_MOUNT_NAME="AzureCloud"
# AZURE_ACCOUNT_NAME="account_name"
# AZURE_ACCOUNT_KEY="account_key"
# AZURE_ACCOUNT_CONTAINER="container_name"

# Not configurable, but different clouds have different admin user names
ADMIN_USER="admin"
if [ "$CLOUD_PROVIDER" = "azure" ]; then
  ADMIN_USER="ghadmin"
fi
