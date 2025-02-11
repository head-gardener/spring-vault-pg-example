# Contents

This repository contains:

- Simple Spring app that tests datasource connection on GETs to `/` (`app`)
- Minimal Postgres configuration (`postgres`)
- Terraform job for generating certificates for vault and configuring it
  (`tf_certs`, `tf_pki` and `tf_db_engine`)
- Vault:
  - running in dev mode
  - with a TLS listener
  - running a database engine for generating ephemeral postgres creds
  - running a PKI
- Vault agent for certs

# Purpose

In this example we achieve secure transfer of secrets between Vault and a
Spring app by using TLS, ephemeral secrets for connecting to Spring's
datasource, Vault-based PKI for establishing communications between the Spring
app and Postgres.

This example **doesn't**:
- Implement mTLS.
- Handle database credential expiration. Once they exipre application stops
  working since Spring Vault Config **can't automatically reconfigure datasource**.
  See [https://secrets-as-a-service.com/posts/hashicorp-vault/spring-boot-max_ttl/](here) for more.
- Handle Vault's seals, token distribution, etc. - it's impossible to do
  programmatically without tools like Ansible, so Vault's dev mode was kept for
  simplicity.

# Execution order

To confirm that the example is working just run `docker compose up` and wait
until application passes its healthcheck. This will

1. Generate certificates and truststore.
1. Launch Vault, create PKI on it with Terraform.
1. Launch agent and Postgres, configure and verify Vault's database engine.
1. Start Spring application and wait for its healthcheck.

After that look through Postgres's connection logs. All connections - including
healthcheck, Spring application's connection pool, Vault's checks and user
creation - should have `SSL enabled` via `TLSv1.3`.

# Details

## Spring

Use `spring-cloud-starter-vault-config` (i.e. Spring Cloud Vault) for sourcing
properties from Vault, `spring-cloud-vault-config-databases` for database
engine. Configure credential expiration handling.
