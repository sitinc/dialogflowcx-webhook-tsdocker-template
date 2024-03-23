variable "project_id" {
  description = "The GCP project name."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The GCP location region."
  type        = string
  sensitive   = true
}

variable "app_name" {
  description = "The project application name."
  type        = string
  sensitive   = true
}

variable "company_name" {
  description = "The project company name."
  type        = string
  sensitive   = true
}

variable "contact_name" {
  description = "The project contact name."
  type        = string
  sensitive   = true
}

variable "contact_url" {
  description = "The project contact URL."
  type        = string
  sensitive   = true
}

variable "contact_email" {
  description = "The project contact email."
  type        = string
  sensitive   = true
}

variable "app_license" {
  description = "The project license."
  type        = string
  sensitive   = true
}

locals {
  app_name_under = replace(var.app_name, "-", "_")
  github_auth_token = "${var.app_name}-github-token"
  github_cxn_id = "${var.app_name}-github-cxn"
  npm_auth_token = "${var.app_name}-npm-token"
  cloud_run_apigw_service_name = "${var.app_name}-apigw"
  cloud_run_apigw_trigger_name = "${var.app_name}-apigw-build"
  cloud_run_apigw_sa_run = "${var.app_name}-apigw-sa"
  cloud_run_apigw_sa_build = "${var.app_name}-build-sa"
  dialogflow_cx_agent_name = var.app_name
  dialogflow_cx_agent_desc = "Dialogflow CX Agent for ${var.app_name}"
  dialogflow_cx_agent_github_repo = "${var.app_name}-cx-dr"
}

variable "dialogflow_cx_voice" {
  description = "The preferred Dialogflow CX voice.  Default is en-US-Neural2-A."
  type        = string
  default     = "en-US-Neural2-A"
}

variable "dialogflow_cx_ssml_gender" {
  description = "The preferred Dialogflow CX SSML gender.  Default for en-US-Neural2-A is SSML_VOICE_GENDER_MALE."
  type        = string
  default     = "SSML_VOICE_GENDER_MALE"
}

variable "dialogflow_cx_timezone" {
  description = "The Dialogflow CX agent timezone.  Default is America/New_York."
  type        = string
  default     = "America/New_York"
}

variable "dialogflow_cx_default_language" {
  description = "The Dialogflow CX agent language_locale.  Default is en."
  type        = string
  default     = "en"
}

variable "oauth_client_id" {
  description = "The OAuth client ID for GCP domain validation."
  type        = string
  sensitive   = true
}

variable "oauth_app_name" {
  description = "The OAuth app name for GCP domain validation."
  type        = string
  sensitive   = true
}

variable "calendly_api_key" {
  description = "The Calendly API key."
  type        = string
  sensitive   = true
}

variable "calendly_uuid" {
  description = "The Calendly UUID."
  type        = string
  sensitive   = true
}

variable "gauth_service_account" {
  description = "The Google Contacts and Calendar API service account."
  type        = string
  sensitive   = true
}

variable "gauth_calendar_id" {
  description = "The Google ID for Calendar API requests."
  type        = string
  sensitive   = true
}

variable "gauth_impersonate_email" {
  description = "The Google email to impersonate with Calendar invite requests."
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "The GitHub repository owner."
  type        = string
  sensitive   = true
}

variable "github_repo" {
  description = "The GitHub repository."
  type        = string
  sensitive   = true
}

variable "github_app_id" {
  description = "The GitHub installation ID."
  type        = string
  sensitive   = true
}

variable "gcp_cloud_run_ingress" {
  description = "The GCP Cloud Run Ingress traffic configuration."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "gcp_cloud_run_req_timeout" {
  description = "The GCP Cloud Run request timeout.  Default is 16s."
  type        = string
  default     = "16s"
}

variable "gcp_cloud_run_username_hdr" {
  description = "The GCP Cloud Run auth username HTTP header name."
  type        = string
  sensitive   = true
}

variable "gcp_cloud_run_password_hdr" {
  description = "The GCP Cloud Run auth password HTTP header name."
  type        = string
  sensitive   = true
}

variable "gcp_cloud_run_min_instances" {
  description = "The GCP Cloud Run minimum number of instances.  Default is 0."
  type        = number
  default     = 0
}

variable "gcp_cloud_run_max_instances" {
  description = "The GCP Cloud Run minimum number of instances.  Default is 0."
  type        = number
  default     = 4
}

variable "environs" {
  description = "A set of environments."
  type = set(string)
  default = ["main", "uat"]
}
