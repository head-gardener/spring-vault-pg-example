terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "4.4.0"
    }
  }
}

variable "vault_token" {
  default = "root"
}

variable "vault_host" {
  default = "localhost"
}

provider "vault" {
  address = "https://${var.vault_host}:8200"
  ca_cert_file = "/certs/vault-cert.pem"
  token = var.vault_token
}

// DB ENGINE

resource "vault_database_secrets_mount" "db" {
  path = "db"

  postgresql {
    name              = "pg"
    username          = "admin"
    password          = "example"
    connection_url    = "postgresql://{{username}}:{{password}}@postgres:5432/dbtest?sslmode=verify-ca&sslrootcert=/certs/vault-pki-ca.pem"
    verify_connection = true
    allowed_roles     = [
      "dev",
    ]
  }
}

resource "vault_database_secret_backend_role" "dev" {
  name    = "dev"
  backend = vault_database_secrets_mount.db.path
  db_name = vault_database_secrets_mount.db.postgresql[0].name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
  ]
}
