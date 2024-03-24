###############
# Enable APIs #
###############

# Enable the Cloud Run API
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

###########################
# Enable Service Accounts #
###########################

# Create dedicated SA account for APIGW Cloud Run.
resource "google_service_account" "apigw_run_sa" {
  depends_on = [ google_project_service.iam_manager_api ]
  account_id   = "${local.cloud_run_apigw_sa_run}"
  display_name = "Dedicated Cloud Run SA for ${local.cloud_run_apigw_service_name} service."
}

# Permisions for dedicated SA account for APIGW Cloud Run.
resource "google_project_iam_member" "cloudrun_secrets_viewer" {
  depends_on = [ google_project_service.iam_manager_api ]
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.apigw_run_sa.email}"
}

#############################
# Create Cloud Run Services #
#############################

locals {
  // Concatenate all secret version IDs into a single string for the annotation
  all_secret_versions = join(
    "-",
    [for secret in google_secret_manager_secret_version.mapped_secret_values : secret.version]
  )
}

resource "google_cloud_run_v2_service" "main" {
  depends_on = [
    google_project_iam_member.cloudrun_secrets_viewer
  ]
  name     = local.cloud_run_apigw_service_name
  location = var.region
  ingress = var.gcp_cloud_run_ingress

  template {
    timeout = var.gcp_cloud_run_req_timeout
    scaling {
      min_instance_count = var.gcp_cloud_run_min_instances
      max_instance_count = var.gcp_cloud_run_max_instances
    }
    containers {
      # image = "gcr.io/${var.project_id}/${local.cloud_run_apigw_service_name}:first"
      # Mock image to solve chicken/egg problem with Cloud Run/Cloud Build deployments with Terraform.
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      env {
        name = "SVC_TITLE"
        value = "(main) ${var.app_name} APIGW"
      }
      dynamic "env" {
        for_each = local.secrets

        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret = google_secret_manager_secret.mapped_secrets[env.key].id
              version = "latest"
            }
          }
        }
      }
    }
    service_account = google_service_account.apigw_run_sa.email

    annotations = {
      "secret-version" = local.all_secret_versions
    }
  }

  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].labels,
      client,
      client_version
    ]
  }
}

resource "google_cloud_run_v2_service" "uat" {
  depends_on = [
    google_project_iam_member.cloudrun_secrets_viewer
  ]
  name     = "${local.cloud_run_apigw_service_name}-uat"
  location = var.region
  ingress = var.gcp_cloud_run_ingress

  template {
    timeout = var.gcp_cloud_run_req_timeout
    scaling {
      min_instance_count = var.gcp_cloud_run_min_instances
      max_instance_count = var.gcp_cloud_run_max_instances
    }
    containers {
      # image = "gcr.io/${var.project_id}/${local.cloud_run_apigw_service_name}:first"
      # Mock image to solve chicken/egg problem with Cloud Run/Cloud Build deployments with Terraform.
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      env {
        name = "SVC_TITLE"
        value = "(uat) ${var.app_name} APIGW"
      }
      dynamic "env" {
        for_each = local.secrets

        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret = google_secret_manager_secret.mapped_secrets[env.key].id
              version = "latest"
            }
          }
        }
      }
    }
    service_account = google_service_account.apigw_run_sa.email

    annotations = {
      "secret-version" = local.all_secret_versions
    }
  }

  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].labels,
      client,
      client_version
    ]
  }
}

######################################
# Configure Cloud Run Ingress Access #
######################################

# Enable public access to MAIN.
resource "google_cloud_run_service_iam_member" "allow_unauthenticated_main" {
  depends_on = [
    google_cloud_run_v2_service.main,
    google_project_service.iam_manager_api,
  ]
  project  = var.project_id
  service  = google_cloud_run_v2_service.main.name
  location = google_cloud_run_v2_service.main.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Enable private access to MAIN (not needed when public, unless you later delete public).
resource "google_cloud_run_service_iam_member" "invoker_main" {
  depends_on = [ google_project_service.iam_manager_api ]
  service  = google_cloud_run_v2_service.main.name
  location = google_cloud_run_v2_service.main.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.apigw_run_sa.email}"
}

# Enable public access to UAT.
resource "google_cloud_run_service_iam_member" "allow_unauthenticated_uat" {
  depends_on = [
    google_project_service.iam_manager_api,
    google_cloud_run_v2_service.uat
  ]
  project  = var.project_id
  service  = google_cloud_run_v2_service.uat.name
  location = google_cloud_run_v2_service.uat.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Enable private access to UAT (not needed when public, unless you later delete public).
resource "google_cloud_run_service_iam_member" "invoker_uat" {
  depends_on = [ google_project_service.iam_manager_api ]
  service  = google_cloud_run_v2_service.uat.name
  location = google_cloud_run_v2_service.uat.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.apigw_run_sa.email}"
}
