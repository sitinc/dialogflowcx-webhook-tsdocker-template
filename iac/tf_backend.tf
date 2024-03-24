terraform {
  backend "gcs" {
    bucket = "__GCP_TFSTATE_BUCKET__"
    prefix = "terraform/state"
  }
}
