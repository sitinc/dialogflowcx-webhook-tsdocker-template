# Enable the Data Loss Prevension API
resource "google_project_service" "dlp_api" {
  service = "dlp.googleapis.com"
  disable_on_destroy = false
}

variable "info_types" {
  description = "Info Types for Inspection"
  type        = set(string)
  default     = [
    "ADVERTISING_ID",
    "AGE",
    "ALL_BASIC",
    "AMERICAN_BANKERS_CUSIP_ID",
    "AUTH_TOKEN",
    "AWS_CREDENTIALS",
    "AZURE_AUTH_TOKEN",
    "BASIC_AUTH_HEADER",
    "BLOOD_TYPE",
    "CANADA_BANK_ACCOUNT",
    "CANADA_BC_PHN",
    "CANADA_DRIVERS_LICENSE_NUMBER",
    "CANADA_OHIP",
    "CANADA_PASSPORT",
    "CANADA_QUEBEC_HIN",
    "CANADA_SOCIAL_INSURANCE_NUMBER",
    "COUNTRY_DEMOGRAPHIC",
    "CREDIT_CARD_NUMBER",
    "CREDIT_CARD_TRACK_NUMBER",
    "DATE",
    "DATE_OF_BIRTH",
    "DOMAIN_NAME",
    "EMAIL_ADDRESS",
    "ENCRYPTION_KEY",
    "ETHNIC_GROUP",
    "FDA_CODE",
    "FEMALE_NAME",
    "FINANCIAL_ACCOUNT_NUMBER",
    "FINLAND_NATIONAL_ID_NUMBER",
    "FIRST_NAME",
    "GCP_API_KEY",
    "GCP_CREDENTIALS",
    "GENDER",
    "GENERIC_ID",
    "HTTP_COOKIE",
    "HTTP_USER_AGENT",
    "IBAN_CODE",
    "ICCID_NUMBER",
    "ICD10_CODE",
    "ICD9_CODE",
    "IMEI_HARDWARE_ID",
    "IMSI_ID",
    "IP_ADDRESS",
    "JSON_WEB_TOKEN",
    "LAST_NAME",
    #"LOCATION", // Not available in all locations.
    "LOCATION_COORDINATES",
    "MAC_ADDRESS",
    "MAC_ADDRESS_LOCAL",
    "MALE_NAME",
    "MARITAL_STATUS",
    "MEDICAL_RECORD_NUMBER",
    "MEDICAL_TERM",
    "OAUTH_CLIENT_SECRET",
    #"ORGANIZATION_NAME", // Not available in all locations.
    "PASSPORT",
    "PASSWORD",
    "PERSON_NAME",
    "PHONE_NUMBER",
    "SSL_CERTIFICATE",
    "STREET_ADDRESS",
    "SWIFT_CODE",
    "US_ADOPTION_TAXPAYER_IDENTIFICATION_NUMBER",
    "US_BANK_ROUTING_MICR",
    "US_DEA_NUMBER",
    "US_DRIVERS_LICENSE_NUMBER",
    "US_EMPLOYER_IDENTIFICATION_NUMBER",
    "US_HEALTHCARE_NPI",
    "US_INDIVIDUAL_TAXPAYER_IDENTIFICATION_NUMBER",
    "US_MEDICARE_BENEFICIARY_ID_NUMBER",
    "US_PASSPORT",
    "US_PREPARER_TAXPAYER_IDENTIFICATION_NUMBER",
    "US_SOCIAL_SECURITY_NUMBER",
    "US_STATE",
    "US_TOLLFREE_PHONE_NUMBER",
    "US_VEHICLE_IDENTIFICATION_NUMBER",
    "VAT_NUMBER",
  ]
}

resource "google_data_loss_prevention_inspect_template" "inspect" {
  parent       = "projects/${var.project_id}/locations/${var.region}"
  display_name = "${var.app_name}-inspect-template"
  inspect_config {
    dynamic "info_types" {
      for_each = var.info_types

      content {
        name = info_types.value
      }
    }
  }
}

resource "google_data_loss_prevention_deidentify_template" "deidentify" {
  parent       = "projects/${var.project_id}/locations/${var.region}"
  display_name = "${var.app_name}-deidentify-template"
  deidentify_config {
    info_type_transformations {
      transformations {
        primitive_transformation {
          replace_with_info_type_config = true
        }
      }
    }
  }
}

#resource "google_storage_bucket" "bucket" {
#  name                        = "dialogflowcx-bucket"
#  location                    = "US"
#  uniform_bucket_level_access = true
#}

resource "google_dialogflow_cx_security_settings" "basic_security_settings" {
  display_name        = "${var.app_name}-security-settings"
  location            = var.region
  redaction_strategy  = "REDACT_WITH_SERVICE"
  redaction_scope     = "REDACT_DISK_STORAGE"
  inspect_template    = google_data_loss_prevention_inspect_template.inspect.id
  deidentify_template = google_data_loss_prevention_deidentify_template.deidentify.id
  purge_data_types    = ["DIALOGFLOW_HISTORY"]
  #audio_export_settings {
  #  gcs_bucket             = google_storage_bucket.bucket.id
  #  audio_export_pattern   = "export"
  #  enable_audio_redaction = true
  #  audio_format           = "OGG"
  #}
  insights_export_settings {
    enable_insights_export = true
  }
  retention_strategy = "REMOVE_AFTER_CONVERSATION"
}
