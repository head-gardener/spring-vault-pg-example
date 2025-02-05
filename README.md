# Contents

This repository contains:

- Simple Spring app that tests datasource connection on GETs to `/` (`app`)
- Minimal Postgres configuration (`postgres`)
- Terraform job for configuring vault (`terraform`)
- A job for generating certs used for connecting to Vault (`certgen`)
- Vault:
 - running in dev mode
 - with a TLS listener
 - running a database engine for generating ephemeral postgres creds

# Purpose

In this example we achieve secure transfer of secrets between Vault and a
Spring app by using TLS, ephemeral secrets for connecting to Spring's
datasource.

This example **doesn't**:
- Use **AppRoles** for authenticating clients into Vault.
- Expire Vault's secrets automatically (or does, but Spring doesn't handle it
  either way).
- Use **Vault's PKI** for establishing TLS connection between Postgres and the
  Spring app.
- Handle Vault's seals, token distribution, etc. - it's impossible to do
  programmatically without tools like Ansible, so Vault's dev mode was kept for
  simplicity.

# Execution order

To confirm that the example is working:

1. `docker compose up certgen` - generate Vault's certificates. You need to do
   this **before** doing anything else and only **once**.
1. `docker compose up vault terraform` - start Vault and apply Terraform
   configuration.
1. `docker compose up postgres app --wait` - start everything else. Once the
   `app` container passes the healthcheck Spring has connected to Postges
   successfully.

# Details

## Spring

Turn `pem` certs into `jsk` truststore for Java. Use
`spring-cloud-starter-vault-config` (i.e. Spring Cloud Vault) for sourcing
properties from Vault.
