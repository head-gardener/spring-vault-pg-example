# Contents

This repository contains:

- Simple Spring app that tests datasource connection on GETs to `/` (`app`)
- Minimal Postgres configuration (`postgres`)
- Terraform job for configuring vault (`tf_pki` and `tf_db_engine`)
- A job for generating certs used for connecting to Vault (`certgen`)
- Vault:
  - running in dev mode
  - with a TLS listener
  - running a database engine for generating ephemeral postgres creds

# Purpose

In this example we achieve secure transfer of secrets between Vault and a
Spring app by using TLS, ephemeral secrets for connecting to Spring's
datasource, Vault-based PKI for establishing communications between the Spring
app and Postgres.

This example **doesn't**:
- Use **AppRoles** for authenticating clients into Vault.
- Implement mTLS.
- Expire Vault's secrets automatically (or does, but Spring doesn't handle it
  either way).
- Handle Vault's seals, token distribution, etc. - it's impossible to do
  programmatically without tools like Ansible, so Vault's dev mode was kept for
  simplicity.

# Execution order

To confirm that the example is working just run `docker compose up` and wait
until application passes its healthcheck. This will

1. Generate certificates and truststore with in `certgen`.
1. Launch Vault, create PKI on it with Terraform, generate Postgres certificates.
1. Launch Postgres, configure and verify Vault's database engine.
1. Start Spring application and wait for its healthcheck.

After that look through Postgres's connection logs. All connections - including
healthcheck, Spring application's connection pool, Vault's checks and user
creation - should have `SSL enabled` via `TLSv1.3`.

# Details

## Spring

Turn `pem` certs into `jks` truststore for Java. Use
`spring-cloud-starter-vault-config` (i.e. Spring Cloud Vault) for sourcing
properties from Vault.
