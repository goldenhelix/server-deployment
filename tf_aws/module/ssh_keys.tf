resource "tls_private_key" "ssh_key" {
  count     = var.ssh_authorized_keys == "" ? 1 : 0
  algorithm = "ED25519"
}

output "ssh_key_name" {
  value = var.ssh_authorized_keys ==  "" ? aws_key_pair.ssh_keys.key_name : var.ssh_authorized_keys
}

# Output the generated public and private keys if generated
output "generated_ssh_public_key" {
  description = "The generated SSH key for the Golden Helix Server"
  value       = var.ssh_authorized_keys == "" ? tls_private_key.ssh_key[0].public_key_openssh : ""
}

output "generated_ssh_private_key" {
  description = "The generated SSH private key for the Golden Helix Server"
  value       = var.ssh_authorized_keys == "" ? tls_private_key.ssh_key[0].private_key_openssh : ""
  sensitive   = true
}

