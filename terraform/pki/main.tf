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

resource "local_file" "ca" {
  filename = "/certs/vault-pki-ca.pem"
  content  = vault_pki_secret_backend_root_cert.vault_pki_ca.certificate
}
