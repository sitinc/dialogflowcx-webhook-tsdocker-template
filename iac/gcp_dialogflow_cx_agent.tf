###############
# Enable APIs #
###############

# Enable the Dialogflow API
resource "google_project_service" "dialogflow_api" {
  service = "dialogflow.googleapis.com"
  disable_on_destroy = false
}

# Enable the Storage API
resource "google_project_service" "storage_api" {
  service = "storage.googleapis.com"
  disable_on_destroy = false
}

#############################################
# Create Dialogflow CX Audio Storage Bucket #
#############################################

resource "google_storage_bucket" "dialogflow_cx_audio_storage" {
  depends_on = [ google_project_service.storage_api ]
  name                        = "${var.app_name}-cx-recordings"
  location                    = var.region
  uniform_bucket_level_access = false
}

resource "google_storage_bucket_iam_binding" "audio_storage_bindings" {
  depends_on = [
    google_project_service.iam_manager_api,
    google_dialogflow_cx_agent.dev,
  ]
  bucket = google_storage_bucket.dialogflow_cx_audio_storage.name
  role   = "roles/storage.objectCreator"

  members = [
    "serviceAccount:service-${data.google_project.main_project.number}@gcp-sa-dialogflow.iam.gserviceaccount.com",
  ]
}

###############################
# Create Dialogflow CX Agents #
###############################

resource "google_dialogflow_cx_agent" "main" {
  depends_on = [
    google_project_service.dialogflow_api,
    github_repository.dialogflow_cx_repo,
    google_storage_bucket.dialogflow_cx_audio_storage,
    google_dialogflow_cx_security_settings.basic_security_settings,
  ]
  display_name              = "${local.dialogflow_cx_agent_name}"
  location                  = var.region
  default_language_code     = var.dialogflow_cx_default_language
  supported_language_codes  = [var.dialogflow_cx_default_language]
  time_zone                 = var.dialogflow_cx_timezone
  project                   = var.project_id
  description               = local.dialogflow_cx_agent_desc
  avatar_uri = "https://cloud.google.com/_static/images/cloud/icons/favicons/onecloud/super_cloud.png"
  enable_stackdriver_logging = true
  enable_spell_correction    = false
  security_settings = "projects/${var.project_id}/locations/${var.region}/securitySettings/${google_dialogflow_cx_security_settings.basic_security_settings.name}"
  speech_to_text_settings {
    enable_speech_adaptation = true
  }
  advanced_settings {
    audio_export_gcs_destination {
      uri = "${google_storage_bucket.dialogflow_cx_audio_storage.url}/prefix-"
    }
    dtmf_settings {
      enabled = true
      max_digits = 1
      finish_digit = "#"
    }
  }
  git_integration_settings {
    github_settings {
      display_name = "main branch"
      repository_uri = "https://api.github.com/repos/${var.github_owner}/${local.dialogflow_cx_agent_github_repo}"
      tracking_branch = "main"
      access_token = data.google_secret_manager_secret_version.github_token_latest.secret_data
      branches = ["main"]
    }
  }
  text_to_speech_settings {
    synthesize_speech_configs = jsonencode({
      en = {
        voice = {
          name = "${var.dialogflow_cx_voice}"
          ssmlGender = "${var.dialogflow_cx_ssml_gender}"
        }
      }
    })
  }
}

resource "google_dialogflow_cx_agent" "uat" {
  depends_on = [
    google_project_service.dialogflow_api,
    github_repository.dialogflow_cx_repo,
    google_storage_bucket.dialogflow_cx_audio_storage,
    google_dialogflow_cx_security_settings.basic_security_settings,
  ]
  display_name              = "${local.dialogflow_cx_agent_name}-uat"
  location                  = var.region
  default_language_code     = var.dialogflow_cx_default_language
  supported_language_codes  = [var.dialogflow_cx_default_language]
  time_zone                 = var.dialogflow_cx_timezone
  project                   = var.project_id
  description               = local.dialogflow_cx_agent_desc
  avatar_uri = "https://cloud.google.com/_static/images/cloud/icons/favicons/onecloud/super_cloud.png"
  enable_stackdriver_logging = true
  enable_spell_correction    = false
  security_settings = "projects/${var.project_id}/locations/${var.region}/securitySettings/${google_dialogflow_cx_security_settings.basic_security_settings.name}"
  speech_to_text_settings {
    enable_speech_adaptation = true
  }
  advanced_settings {
    audio_export_gcs_destination {
      uri = "${google_storage_bucket.dialogflow_cx_audio_storage.url}/prefix-"
    }
    dtmf_settings {
      enabled = true
      max_digits = 1
      finish_digit = "#"
    }
  }
  git_integration_settings {
    github_settings {
      display_name = "uat branch"
      repository_uri = "https://api.github.com/repos/${var.github_owner}/${local.dialogflow_cx_agent_github_repo}"
      tracking_branch = "uat"
      access_token = data.google_secret_manager_secret_version.github_token_latest.secret_data
      branches = ["uat"]
    }
  }
  text_to_speech_settings {
    synthesize_speech_configs = jsonencode({
      en = {
        voice = {
          name = "${var.dialogflow_cx_voice}"
          ssmlGender = "${var.dialogflow_cx_ssml_gender}"
        }
      }
    })
  }
}

resource "google_dialogflow_cx_agent" "dev" {
  depends_on = [
    google_project_service.dialogflow_api,
    github_repository.dialogflow_cx_repo,
  ]
  display_name              = "${local.dialogflow_cx_agent_name}-dev"
  location                  = var.region
  default_language_code     = var.dialogflow_cx_default_language
  supported_language_codes  = [var.dialogflow_cx_default_language]
  time_zone                 = var.dialogflow_cx_timezone
  project                   = var.project_id
  description               = local.dialogflow_cx_agent_desc
  avatar_uri = "https://cloud.google.com/_static/images/cloud/icons/favicons/onecloud/super_cloud.png"
  enable_stackdriver_logging = true
  enable_spell_correction    = false
  speech_to_text_settings {
    enable_speech_adaptation = true
  }
  advanced_settings {
    dtmf_settings {
      enabled = true
      max_digits = 1
      finish_digit = "#"
    }
  }
  git_integration_settings {
    github_settings {
      display_name = "dev branch"
      repository_uri = "https://api.github.com/repos/${var.github_owner}/${local.dialogflow_cx_agent_github_repo}"
      tracking_branch = "dev"
      access_token = data.google_secret_manager_secret_version.github_token_latest.secret_data
      branches = ["dev"]
    }
  }
  text_to_speech_settings {
    synthesize_speech_configs = jsonencode({
      en = {
        voice = {
          name = "${var.dialogflow_cx_voice}"
          ssmlGender = "${var.dialogflow_cx_ssml_gender}"
        }
      }
    })
  }
}

#resource "google_dialogflow_cx_flow" "start_flow" {
#  name         = "your-start-flow-name"
#  display_name = "Start Flow"
#  description  = "The initial flow of the agent."
#  parent       = google_dialogflow_cx_agent.agent.id
#}

###################
# Create Webhooks #
###################

resource "google_dialogflow_cx_webhook" "prod_main_webhook" {
  depends_on = [
    google_dialogflow_cx_agent.main,
    google_cloud_run_v2_service.main,
    random_password.webhook_username,
    random_password.webhook_password,
  ]
  parent       = google_dialogflow_cx_agent.main.id
  display_name = "main-webhook"
  disabled     = false
  timeout      = var.gcp_cloud_run_req_timeout

  # Webhook configuration
  generic_web_service {
    uri = google_cloud_run_v2_service.main.uri
    
    # Adding custom HTTP headers
    request_headers = {
      "${var.gcp_cloud_run_username_hdr}" = "${random_password.webhook_username.result}"
      "${var.gcp_cloud_run_password_hdr}" = "${random_password.webhook_password.result}"
    }
  }
}

resource "google_dialogflow_cx_webhook" "prod_uat_webhook" {
  depends_on = [
    google_dialogflow_cx_agent.main,
    google_cloud_run_v2_service.uat,
    random_password.webhook_username,
    random_password.webhook_password,
  ]
  parent       = google_dialogflow_cx_agent.main.id
  display_name = "uat-webhook"
  disabled     = false
  timeout      = var.gcp_cloud_run_req_timeout

  # Webhook configuration
  generic_web_service {
    uri = google_cloud_run_v2_service.uat.uri
    
    # Adding custom HTTP headers
    request_headers = {
      "${var.gcp_cloud_run_username_hdr}" = "${random_password.webhook_username.result}"
      "${var.gcp_cloud_run_password_hdr}" = "${random_password.webhook_password.result}"
    }
  }
}

resource "google_dialogflow_cx_webhook" "uat_prod_webhook" {
  depends_on = [
    google_dialogflow_cx_agent.uat,
    google_cloud_run_v2_service.main,
    random_password.webhook_username,
    random_password.webhook_password,
  ]
  parent       = google_dialogflow_cx_agent.uat.id
  display_name = "main-webhook"
  disabled     = false
  timeout      = var.gcp_cloud_run_req_timeout

  # Webhook configuration
  generic_web_service {
    uri = google_cloud_run_v2_service.main.uri

    # Adding custom HTTP headers
    request_headers = {
      "${var.gcp_cloud_run_username_hdr}" = "${random_password.webhook_username.result}"
      "${var.gcp_cloud_run_password_hdr}" = "${random_password.webhook_password.result}"
    }
  }
}

resource "google_dialogflow_cx_webhook" "uat_uat_webhook" {
  depends_on = [
    google_dialogflow_cx_agent.uat,
    google_cloud_run_v2_service.uat,
    random_password.webhook_username,
    random_password.webhook_password,
  ]
  parent       = google_dialogflow_cx_agent.uat.id
  display_name = "uat-webhook"
  disabled     = false
  timeout      = var.gcp_cloud_run_req_timeout

  # Webhook configuration
  generic_web_service {
    uri = google_cloud_run_v2_service.uat.uri

    # Adding custom HTTP headers
    request_headers = {
      "${var.gcp_cloud_run_username_hdr}" = "${random_password.webhook_username.result}"
      "${var.gcp_cloud_run_password_hdr}" = "${random_password.webhook_password.result}"
    }
  }
}

####################################
# Create Backup/Restore Repository #
####################################

resource "github_repository" "dialogflow_cx_repo" {
  name        = "${local.dialogflow_cx_agent_github_repo}"
  description = "Backup/Restore repository for ${var.app_name}'s Dialogflow CX Agent."
  visibility = "private"

  template {
    owner = "sitinc"
    repository = "dialogflow-cx-dr-template"
    include_all_branches = true
  }

  lifecycle {
    ignore_changes = [
      template,
    ]
  }
}
