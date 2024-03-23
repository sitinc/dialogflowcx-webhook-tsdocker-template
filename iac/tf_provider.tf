provider "google" {
  project = var.project_id
  region  = var.region
  user_project_override = true
  billing_project       = var.project_id
}

provider "github" {
  token        = data.google_secret_manager_secret_version.github_token_latest.secret_data
  owner        = var.github_owner
}

provider "random" { }

provider "local" { }


terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
    random = {
      source  = "hashicorp/random"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}