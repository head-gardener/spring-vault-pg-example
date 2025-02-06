set -exo pipefail
cd certs

# CA
openssl req -x509 \
  -newkey rsa:4096 \
  -days 365 \
  -keyout ca-key.pem \
  -noenc \
  -out ca-cert.pem \
  -subj "/CN=VaultCA"

# Vault cert
openssl genpkey -algorithm RSA -out vault-key.pem
openssl req -new \
  -key vault-key.pem \
  -out vault.csr \
  -addext "subjectAltName = IP:127.0.0.1, DNS:vault, DNS:localhost" \
  -subj "/CN=vault"
openssl x509 -req \
  -in vault.csr \
  -CA ca-cert.pem \
  -CAkey ca-key.pem \
  -CAcreateserial \
  -out vault-cert.pem \
  -days 365 \
  -copy_extensions copy

# Truststore for Java
rm -f app-keystore.jks
keytool -importcert \
  -file /certs/ca-cert.pem \
  -keystore app-keystore.jks \
  -alias vault-ca \
  -trustcacerts \
  -noprompt \
  -storepass vault-ca

chmod 666 ./*
