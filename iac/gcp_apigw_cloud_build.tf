###############
# Enable APIs #
###############

# Enable the Cloud Source Repositories API
resource "google_project_service" "cloudsourcerepos_api" {
  service = "sourcerepo.googleapis.com"
  disable_on_destroy = false
}

# Enable the Cloud Build API
resource "google_project_service" "cloudbuild_api" {
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# Enable the Artifact Registry API
resource "google_project_service" "artifactregistry_api" {
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

###########################
# Enable Service Accounts #
###########################

# Create dedicated SA account for APIGW Cloud Build.
resource "google_service_account" "apigw_build_sa" {
  depends_on = [ google_project_service.iam_manager_api ]
  account_id   = "${local.cloud_run_apigw_sa_build}"
  display_name = "Dedicated Cloud Build SA for ${local.cloud_run_apigw_service_name} service."
}

# Permit Dedicated Build SA access to read secrets.
resource "google_project_iam_member" "cloudbuild_secrets_viewer" {
  depends_on = [ google_project_service.iam_manager_api ]
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.apigw_build_sa.email}"
}

# Permit all Build SAs to Deploy Cloud Run
resource "google_project_iam_member" "cloudbuild_cloudrun_deployer" {
  depends_on = [ google_project_service.iam_manager_api ]
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.apigw_build_sa.email}"
}

resource "google_project_iam_member" "cloudbuild_sa1_cloudrun_deployer" {
  depends_on = [ google_project_service.iam_manager_api ]
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${data.google_project.main_project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_sa2_cloudrun_deployer" {
  depends_on = [ google_project_service.iam_manager_api ]
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:service-${data.google_project.main_project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Permit all Build SAs to Act-as Dedicated Cloud Run SA
resource "google_project_iam_member" "cloudbuild_cloudrun_actas" {
  depends_on = [ google_project_service.iam_manager_api ]
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.apigw_build_sa.email}"
}

resource "google_project_iam_member" "cloudbuild_sa1_cloudrun_actas" {
  depends_on = [ google_project_service.iam_manager_api ]
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${data.google_project.main_project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_sa2_cloudrun_actas" {
  depends_on = [ google_project_service.iam_manager_api ]
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:service-${data.google_project.main_project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}


//service-666043410170@gcp-sa-cloudbuild.iam.gserviceaccount.com


#######################
# Access Core Secrets #
#######################

# Access the NPM auth token secret
data "google_secret_manager_secret" "npm_token" {
  project = var.project_id
  secret_id = "${local.npm_auth_token}"
}

data "google_project" "main_project" {
  project_id = var.project_id
}

data "google_iam_policy" "buildagent_secretAccessor" {
  depends_on = [
    data.google_project.main_project,
  ]
    binding {
        role = "roles/secretmanager.secretAccessor"
        members = [
          "serviceAccount:${data.google_project.main_project.number}@cloudbuild.gserviceaccount.com",
          "serviceAccount:service-${data.google_project.main_project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
          "serviceAccount:${google_service_account.apigw_build_sa.email}",
        ]
    }
}

resource "google_secret_manager_secret_iam_policy" "npm_token_policy" {
  depends_on = [
    google_project_service.secret_manager_api,
    google_project_service.iam_manager_api,
  ]
  project = var.project_id
  secret_id = data.google_secret_manager_secret.npm_token.secret_id
  policy_data = data.google_iam_policy.buildagent_secretAccessor.policy_data
}

# Access the GitHub auth token secret
data "google_secret_manager_secret" "github_token" {
  project = var.project_id
  secret_id = local.github_auth_token
}

data "google_secret_manager_secret_version" "github_token_latest" {
  secret = data.google_secret_manager_secret.github_token.id
}

data "google_iam_policy" "serviceagent_secretAccessor" {
    binding {
        role = "roles/secretmanager.secretAccessor"
        members = [
          "serviceAccount:${data.google_project.main_project.number}@cloudbuild.gserviceaccount.com",
          "serviceAccount:service-${data.google_project.main_project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
          "serviceAccount:${google_service_account.apigw_build_sa.email}",
        ]
    }
}

resource "google_secret_manager_secret_iam_policy" "github_token_policy" {
  depends_on = [
    google_project_service.secret_manager_api,
    google_project_service.iam_manager_api,
  ]
  project = var.project_id
  secret_id = data.google_secret_manager_secret.github_token.secret_id
  policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data
}

############################################
# Link GitHub to Cloud Source Repositories #
############################################

# Create the GitHub connection.
resource "google_cloudbuildv2_connection" "my_connection" {
    depends_on = [
      google_project_service.cloudsourcerepos_api,
      google_secret_manager_secret_iam_policy.github_token_policy,
    ]
    project = var.project_id
    location = var.region
    name = local.github_cxn_id

    github_config {
        app_installation_id = var.github_app_id
        authorizer_credential {
            oauth_token_secret_version = "projects/${var.project_id}/secrets/${local.github_auth_token}/versions/latest"
        }
    }
}

# Link the GitHub repository.
resource "google_cloudbuildv2_repository" "my_repository" {
  depends_on = [
    google_project_service.cloudsourcerepos_api,
    google_cloudbuildv2_connection.my_connection,
  ]
  project = var.project_id
  location = var.region
  name = "${var.github_owner}-${var.github_repo}"
  parent_connection = google_cloudbuildv2_connection.my_connection.name
  remote_uri = "https://github.com/${var.github_owner}/${var.github_repo}.git"
}

#########################
# Create Build Triggers #
#########################

# Create the main branch trigger.
resource "google_cloudbuild_trigger" "main" {
  depends_on = [
    google_project_service.cloudsourcerepos_api,
    google_project_service.cloudbuild_api,
    google_cloudbuildv2_connection.my_connection,
    google_cloudbuildv2_repository.my_repository,
  ]
  project = var.project_id
  name = "${local.cloud_run_apigw_trigger_name}-prod"
  description = "Trigger for changes to the main branch"
  location = var.region

  repository_event_config {
    repository = "projects/${var.project_id}/locations/${var.region}/connections/${local.github_cxn_id}/repositories/${var.github_owner}-${var.github_repo}"
    push {
      branch = "^main$"
    }
  }
  
  substitutions = {
    _DEPLOY_REGION: var.region,
    _TRIGGER_ID: "${local.cloud_run_apigw_trigger_name}-prod",
    _AR_HOSTNAME: "us-central1-docker.pkg.dev",
    _PLATFORM: "managed",
    _APP_NAME: var.app_name,
    _SERVICE_NAME: "${local.cloud_run_apigw_service_name}",
  }

  filename = "iac/cloudbuild.yaml"

  included_files = [
    "**",
  ]
  # service_account = "projects/${var.project_id}/serviceAccounts/${google_service_account.apigw_build_sa.email}"
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
  tags = [
    "gcp-cloud-build-deploy-cloud-run",
    "gcp-cloud-build-deploy-cloud-run-managed",
    local.cloud_run_apigw_service_name,
    var.app_name,
  ]
}

# Create the uat branch trigger.
resource "google_cloudbuild_trigger" "uat" {
  depends_on = [
    google_project_service.cloudsourcerepos_api,
    google_project_service.cloudbuild_api,
    google_cloudbuildv2_connection.my_connection,
    google_cloudbuildv2_repository.my_repository,
  ]
  project = var.project_id
  name = "${local.cloud_run_apigw_trigger_name}-uat"
  description = "Trigger for changes to the uat branch"
  location = var.region

  repository_event_config {
    repository = "projects/${var.project_id}/locations/${var.region}/connections/${local.github_cxn_id}/repositories/${var.github_owner}-${var.github_repo}"
    push {
      branch = "^uat$"
    }
  }
  
  substitutions = {
    _DEPLOY_REGION: var.region,
    _TRIGGER_ID: "${local.cloud_run_apigw_trigger_name}-uat",
    _AR_HOSTNAME: "us-central1-docker.pkg.dev",
    _PLATFORM: "managed",
    _APP_NAME: var.app_name,
    _SERVICE_NAME: "${local.cloud_run_apigw_service_name}-uat",
  }

  filename = "iac/cloudbuild.yaml"

  included_files = [
    "**",
  ]
  # service_account = "projects/${var.project_id}/serviceAccounts/${google_service_account.apigw_build_sa.email}"
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
  tags = [
    "gcp-cloud-build-deploy-cloud-run",
    "gcp-cloud-build-deploy-cloud-run-managed",
    "${local.cloud_run_apigw_service_name}-uat",
    var.app_name,
  ]
}

#######################
# Trigger First Build #
#######################

# Trigger the first main build.
resource "null_resource" "trigger_prod_build" {
  depends_on = [
    google_cloudbuild_trigger.main,
    google_secret_manager_secret_iam_policy.npm_token_policy,
    local_file.out_swagger_json,
    local_file.out_tos_txt,
    google_artifact_registry_repository_iam_policy.policy,
    google_project_iam_member.cloudbuild_sa1_cloudrun_deployer,
    google_project_iam_member.cloudbuild_sa2_cloudrun_deployer,
  ]

  provisioner "local-exec" {
    command = "cd .. && gcloud beta builds submit --config=./iac/cloudbuild.yaml --project=${var.project_id}  --substitutions REPO_NAME=${var.github_repo},COMMIT_SHA=first,_APP_NAME=${var.app_name},_SERVICE_NAME=${local.cloud_run_apigw_service_name},_TRIGGER_ID=${google_cloudbuild_trigger.main.trigger_id}"
  }
}

# Trigger the first uat build.
resource "null_resource" "trigger_uat_build" {
  depends_on = [
    google_cloudbuild_trigger.uat,
    google_secret_manager_secret_iam_policy.npm_token_policy,
    local_file.out_swagger_json,
    local_file.out_tos_txt,
    google_artifact_registry_repository_iam_policy.policy,
    google_project_iam_member.cloudbuild_sa1_cloudrun_deployer,
    google_project_iam_member.cloudbuild_sa2_cloudrun_deployer,
  ]

  provisioner "local-exec" {
    command = "cd .. && gcloud beta builds submit --config=./iac/cloudbuild.yaml --project=${var.project_id}  --substitutions REPO_NAME=${var.github_repo},COMMIT_SHA=first,_APP_NAME=${var.app_name},_SERVICE_NAME=${local.cloud_run_apigw_service_name}-uat,_TRIGGER_ID=${google_cloudbuild_trigger.uat.trigger_id}"
  }
}

resource "google_artifact_registry_repository" "my_repository" {
  depends_on = [
    google_project_service.artifactregistry_api,
  ]

  provider = google

  location      = var.region # Match the provider region if appropriate
  repository_id = "cloud-run-source-deploy"
  description   = "Repository for Cloud Run and Cloud Build artifacts"
  format        = "DOCKER"

  labels = {
    environment = "production"
  }
}

data "google_iam_policy" "artifact_registry_writer" {
  binding {
    role = "roles/artifactregistry.writer"

    members = [
      "serviceAccount:${data.google_project.main_project.number}@cloudbuild.gserviceaccount.com",
      "serviceAccount:service-${data.google_project.main_project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
      "serviceAccount:${google_service_account.apigw_build_sa.email}",
    ]
  }
}

resource "google_artifact_registry_repository_iam_policy" "policy" {
  depends_on = [
    google_project_service.iam_manager_api,
    google_project_service.artifactregistry_api,
  ]
  location      = google_artifact_registry_repository.my_repository.location
  repository    = google_artifact_registry_repository.my_repository.repository_id
  policy_data = data.google_iam_policy.artifact_registry_writer.policy_data
}
