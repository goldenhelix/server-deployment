# Golden Helix Server Deployment

This project will deploy Golden Helix Server in either AWS or Azure within a
single region of your choice.

A VPC/VNet is created with 2 subnets (Public and Private). The Public subnet is used
for the Golden Helix Server. The Private subnet is used for the Workflow Agents.

> ***NOTE:*** Both OpenTofu (tofu) and HashiCorp Terraform are supported. You
> can replace references to 'terraform' in this documentation with 'tofu' if you
> are using OpenTofu. Also, edit `env.sh` and set `TF=tofu` to use OpenTofu.

## Configuration Files

The deployment configuration is split between two locations:

1. Top-level `env.sh` - Contains server configuration settings that are applied after deployment
2. Cloud-specific directory (`tf_aws` or `tf_azure`) - Contains infrastructure configuration

### Server Configuration (env.sh)

Edit the variables in `env.sh` to customize the server configuration. This file contains settings for:
- License key
- Server name
- Workspace details
- Timezone and locale settings
- SAML configuration
- Optional integrations (Sentieon, SSL, DxFuse, BaseSpace, Azure Blob Storage)

### Infrastructure Configuration

Navigate to either `tf_aws` or `tf_azure` directory based on your chosen cloud provider:

1. Edit the variables in `terraform.tfvars` to customize the deployment
2. See `variables.tf` for descriptions and validation expectations for the variables

# Pre-Configuration

### Primary user email activation

To activate a license key, the primary_user must be registered with Golden
Helix. You can [Register with Golden
Helix](https://www.goldenhelix.com/auth/registration/) ahead of time. Make sure
to verify the email address and accept the terms of service.

### DNS

Set the domain name to `your_institute.varseq.com`, which Golden Helix will
provide with the license.

The varseq.com DNS entry will automatically get updated as part of the install
process and SSL certificates will be provisioned to the machine. This will work
even if the server is behind an IP whitelist, NAT gateway, or firewall, as long
as the server has outbound internet access.

If you are using a custom domain, you will need to update the DNS records to
point to the public IP address of the server. You will also need to provide the
SSL certificate for the domain, otherwise self-signed certificates will be used.

## SMTP

The server will send emails to users for password resets, notifications, and
invites as well as security events. SMTP is required for these emails to be sent.

You can configure the SMTP server by editing `configs/smtp.yaml` before running
the `./create_server.sh` script.

### SSH Key Pair

You may allow the deployment to generate an SSH key pair for you, or you may
provide the public key of a pre-generated key pair in the `ssh_authorized_keys`
variable. Save the private key as ssh_key.pem (chmod 400) in this directory.

### Cloud Provider Credentials

#### AWS
Create a user via the IAM console that will be used for the terraform
deployment. Give the user **Programmatic Access** and attach the existing policy
**AdministratorAccess**. Save the key and key secret in a file called
`secrets.tfvars` in the `tf_aws` directory. See `tf_aws/secrets.tfvars.example`
for an example.

#### Azure
Create a service principal with appropriate permissions for the deployment. Save the
client ID, client secret, subscription ID, and tenant ID.

For authentication, it is recommended to simply use the Azure CLI. You can login
with `az login` and then select the subscription you want to use. Just use the
same subscription ID in the `tf_azure/terraform.tfvars` file.

# Deployment Steps

1. Initialize the project in your chosen cloud provider's directory:

       cd tf_aws  # or tf_azure
       terraform init

3. Verify the configuration

       cd tf_aws
       terraform init
       terraform plan -var-file secrets.tfvars

       # or

       cd tf_azure
       terraform init
       terraform plan # assuming you ran `az login` and selected the subscription

4. Review the post-installation server configuration variables that are run as
   part of `./create_server.sh`.

5. Review and run the `./create_server.sh` to deploy and configure the server.

       ./create_server.sh

6. Login to the Deployment as an Admin via the domain defined; e.g., `https://your_institution.varseq.com`. Your user password is generated and outputted in the terminal after the `./create_server.sh` script is run.

7. View the in-app documentation for further configuration steps.
