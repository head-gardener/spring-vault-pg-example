pid_file = "/tmp/pidfile"

exit_after_auth = false

auto_auth {
  method {
    type = "token_file"

    config = {
      token_file_path = "/token"
    }
  }

  sinks {
    sink {
      type = "file"

      config = {
        path = "/tmp/token"
        mode = 600
      }
    }
  }
}

template_config {
  exit_on_retry_failure = true
  static_secret_render_interval = "10m"
  max_connections_per_host = 30
}

template {
  contents    = <<EOT
{{ with pkiCert "pki/issue/postgres" "common_name=postgres" "alt_names=postgres,localhost" }}
{{ .Data.Cert }}
{{ .Data.Key }}
{{ end }}
  EOT
  destination = "/pg-certs/postgres-bundle.pem"
  perms       = "0600"
  command     = "chown 999:999 /pg-certs/postgres-bundle.pem"

  error_on_missing_key = true
}
