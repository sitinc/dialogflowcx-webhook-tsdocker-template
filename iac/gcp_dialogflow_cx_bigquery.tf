###############
# Enable APIs #
###############

resource "google_project_service" "bigquery_api" {
  service = "bigquery.googleapis.com"

  disable_on_destroy = false
}

resource "google_bigquery_dataset" "dialogflow_logs_dataset" {
  dataset_id                  = "${local.app_name_under}_dataset"
  location                    = var.region
  description                 = "Dataset for storing ${var.app_name}'s data warehouse tables."
  delete_contents_on_destroy  = true

  access {
    role          = "roles/bigquery.dataEditor"
    user_by_email = "service-${data.google_project.main_project.number}@gcp-sa-dialogflow.iam.gserviceaccount.com"
  }
  #labels = {
  #  env = "production"
  #}
  lifecycle {
    ignore_changes = [access]
  }
}

resource "google_bigquery_table" "dialogflow_logs_table" {
  dataset_id = google_bigquery_dataset.dialogflow_logs_dataset.dataset_id
  table_id   = "interaction_logs"
  deletion_protection = false

  schema = jsonencode([
    {
      name = "project_id",
      type = "STRING"
    },
    {
      name = "agent_id",
      type = "STRING"
    },
    {
      name = "conversation_name",
      type = "STRING"
    },
    {
      name = "turn_position",
      type = "INTEGER"
    },
    {
      name = "request_time",
      type = "TIMESTAMP"
    },
    {
      name = "language_code",
      type = "STRING"
    },
    {
      name = "request",
      type = "JSON"
    },
    {
      name = "response",
      type = "JSON"
    },
    {
      name = "partial_responses",
      type = "JSON"
    },
    {
      name = "derived_data",
      type = "JSON"
    },
    {
      name = "conversation_signals",
      type = "JSON"
    },
    {
      name = "bot_answer_feedback",
      type = "JSON"
    }
  ])
}