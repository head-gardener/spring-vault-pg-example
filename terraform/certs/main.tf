terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }
  }
  backend "local" {
    path = "/certs/tfstate"
  }
}

provider "tls" {
}

provider "local" {
}

variable "target_uid" {
  default = "100"
}

variable "target_gid" {
  default = "1000"
}

resource "tls_private_key" "ca" {
  algorithm = "ED25519"
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  validity_period_hours = 8760
  early_renewal_hours = 168

  is_ca_certificate = true
  allowed_uses      = [
    "cert_signing",
    "crl_signing",
  ]

  subject {
    common_name  = "Vault TLS CA"
  }

  set_subject_key_id = true
}

resource "tls_private_key" "vault" {
  algorithm = "ED25519"
}

resource "tls_cert_request" "vault" {
  private_key_pem = tls_private_key.vault.private_key_pem

  subject {
    common_name  = "vault"
    organization = "ACME Examples, Inc"
  }

  dns_names = [
    "vault",
    "localhost",
  ]

  ip_addresses = [
    "127.0.0.1",
  ]
}

resource "tls_locally_signed_cert" "vault" {
  cert_request_pem   = tls_cert_request.vault.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 768
  early_renewal_hours = 48

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "local_sensitive_file" "vault_pkey" {
  filename        = "/certs/vault-key.pem"
  content         = tls_private_key.vault.private_key_pem
  file_permission = "0600"

  provisioner "local-exec" {
    command = <<EOT
      chown "$UID:$GID" "$FILE"
    EOT
    environment = {
      UID  = var.target_uid
      GID  = var.target_gid
      FILE = self.filename
    }
  }
}

resource "local_file" "ca" {
  filename        = "/certs/ca-cert.pem"
  content         = tls_locally_signed_cert.vault.cert_pem
  file_permission = "0644"
}

resource "local_file" "vault_cert" {
  filename        = "/certs/vault-cert.pem"
  content         = tls_locally_signed_cert.vault.cert_pem
  file_permission = "0644"
}
