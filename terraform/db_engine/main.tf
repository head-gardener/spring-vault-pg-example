terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "~> 4.6.0"
    }
  }
}

provider "vault" { }

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
  name        = "dev"
  backend     = vault_database_secrets_mount.db.path
  db_name     = vault_database_secrets_mount.db.postgresql[0].name
  max_ttl     = 2678400 # month
  default_ttl = 2678400
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
  ]
}
