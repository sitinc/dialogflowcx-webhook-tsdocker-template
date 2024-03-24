# Enable the Secret Manager API
resource "google_project_service" "secret_manager_api" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "random_password" "webhook_username" {
  length           = 16
  special          = false
}

resource "random_password" "webhook_password" {
  length           = 32
  special          = true
  override_special = "-_%@."
}

# Create the Secrets Mapping
locals {
  secrets = {
    "AUTH_USERNAME_HDR" = var.gcp_cloud_run_username_hdr,
    "AUTH_USERNAME_VAL" = random_password.webhook_username.result,
    "AUTH_PASSWORD_HDR" = var.gcp_cloud_run_password_hdr,
    "AUTH_PASSWORD_VAL" = random_password.webhook_password.result,
  }
}

# Create the secrets.
resource "google_secret_manager_secret" "mapped_secrets" {
  depends_on = [
    google_project_service.secret_manager_api,
  ]
  
  for_each = local.secrets

  secret_id = each.key

  replication {
    auto {}
  }
}

# Create the secret versions.
resource "google_secret_manager_secret_version" "mapped_secret_values" {
  depends_on = [
    google_secret_manager_secret.mapped_secrets,
  ]
  
  for_each = local.secrets

  secret      = google_secret_manager_secret.mapped_secrets[each.key].id
  secret_data = each.value
}
