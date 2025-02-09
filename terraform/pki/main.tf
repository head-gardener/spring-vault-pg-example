terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "4.4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
}

provider "local" {}

provider "vault" {}

// PKI

resource "vault_mount" "pki" {
  path = "pki"
  type = "pki"

  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 315360000
}

resource "vault_pki_secret_backend_root_cert" "vault_pki_ca" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "vault"
  ttl         = 315360000
  issuer_name = "vault_pki_ca"
}

resource "vault_pki_secret_backend_issuer" "vault_pki_ca" {
  backend                        = vault_mount.pki.path
  issuer_ref                     = vault_pki_secret_backend_root_cert.vault_pki_ca.issuer_id
  issuer_name                    = vault_pki_secret_backend_root_cert.vault_pki_ca.issuer_name
  revocation_signature_algorithm = "SHA256WithRSA"
}

resource "vault_pki_secret_backend_config_urls" "config-urls" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["http://vault:8200/v1/pki/ca"]
  crl_distribution_points = ["http://vault:8200/v1/pki/crl"]
}

resource "vault_pki_secret_backend_role" "postgres" {
  backend            = vault_mount.pki.path
  name               = "postgres"
  ttl                = 86400
  key_type           = "rsa"
  key_bits           = 4096
  allowed_domains    = ["postgres"]
  allow_bare_domains = true
  allow_subdomains   = false
  allow_localhost    = true
  allow_ip_sans      = false
}

resource "vault_pki_secret_backend_cert" "postgres" {
  issuer_ref  = vault_pki_secret_backend_issuer.vault_pki_ca.issuer_ref
  backend     = vault_pki_secret_backend_role.postgres.backend
  name        = vault_pki_secret_backend_role.postgres.name
  common_name = "postgres"
  alt_names   = ["postgres", "localhost"]
  ttl         = 3600
  revoke      = true
}

resource "local_sensitive_file" "postgres_pkey" {
  filename        = "/certs/postgres-key.pem"
  content         = vault_pki_secret_backend_cert.postgres.private_key
  file_permission = "0600"

  # postgres user in the pg container, postgresql needs it
  provisioner "local-exec" {
    command = "chown 999:999 ${local_sensitive_file.postgres_pkey.filename}"
  }
}

resource "local_file" "ca" {
  filename = "/certs/vault-pki-ca.pem"
  content  = vault_pki_secret_backend_cert.postgres.ca_chain
}

resource "local_file" "postgres_cert" {
  filename = "/certs/postgres-cert.pem"
  content  = vault_pki_secret_backend_cert.postgres.certificate
}
