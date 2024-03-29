#!/usr/bin/env bash

# Login first with gcloud
# gcloud auth login

current_gcp_project=$(gcloud config get-value project)

echo -n "Enter GCP project [$current_gcp_project]: "
read -r gcp_project

if [[ -z "$gcp_project" ]]; then
  if [[ -z "$current_gcp_project" ]]; then
    echo "Error: GCP project is required, and no default project is set."
    exit 1
  fi
  gcp_project=$current_gcp_project
  echo "    Using GCP project: $gcp_project"
fi

current_gcp_region=$(gcloud config get-value compute/region)

echo -n "Enter GCP region [$current_gcp_region]: "
read -r gcp_region

if [[ -z "$gcp_region" ]]; then
  if [[ -z "$current_gcp_region" ]]; then
    echo "Error: GCP region is required, and no default region is set."
    exit 1
  fi
  gcp_region=$current_gcp_region
  echo "    Using GCP region: $gcp_region"
fi

current_app_name=$(basename "$(dirname "$(pwd)")")

echo -n "Enter App name [$current_app_name]: "
read -r app_name

if [[ -z "$app_name" ]]; then
  app_name=$current_app_name
  echo "    Using App name: $app_name"
fi

# Collect GitHub repository information.
current_github_remote_url=$(git remote get-url origin)
current_github_repo_owner=$(echo $current_github_remote_url | sed -n 's/.*:\/\/.*\/\([^\/]*\)\/\([^\.]*\).*/\1/p')
current_github_repo_name=$(echo $current_github_remote_url | sed -n 's/.*:\/\/.*\/\([^\/]*\)\/\([^\.]*\).*/\2/p')

echo -n "Enter GitHub Repo Owner [$current_github_repo_owner]: "
read -r github_repo_owner

if [[ -z "$github_repo_owner" ]]; then
  github_repo_owner=$current_github_repo_owner
  echo "    Using GitHub Repo Owner: $github_repo_owner"
fi

echo -n "Enter GitHub Repo Name [$current_github_repo_name]: "
read -r github_repo_name

if [[ -z "$github_repo_name" ]]; then
  github_repo_name=$current_github_repo_name
  echo "    Using GitHub Repo Name: $github_repo_name"
fi

echo "*To get the GitHub Cloud Build App Id, see https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github#connecting_a_github_host_programmatically"
echo -n "Enter GitHub Cloud Build App Id: "
read -r github_app_id

if [[ -z "$github_app_id" ]]; then
  echo "Error: GitHub App ID is required."
  exit 1
fi

echo -n "Enter GitHub API Token: "
read -r -s github_api_token
echo ""

if [[ -z "$github_api_token" ]]; then
  echo "Error: GitHub API Token is required."
  exit 1
fi

echo -n "Enter NPM API Token: "
read -r -s npm_api_token
echo ""

if [[ -z "$npm_api_token" ]]; then
  echo "Error: NPM API Token is required."
  exit 1
fi

echo "    Initializing Terraform Backend..."

# Set gcloud project and billing.
gcloud config set project "$gcp_project"

# Enable Google Cloud Resource Manager API
echo "Enabling Google Cloud Resource Manager APIs"
gcloud services enable cloudresourcemanager.googleapis.com

gcloud auth application-default set-quota-project "$gcp_project"

# Enable Google Compute API
echo "Enabling Google Compute APIs"
gcloud services enable compute.googleapis.com

# Set gcloud region
gcloud config set compute/region "$gcp_region"

# Enable Google IAM API
echo "Enabling Google IAM APIs"
gcloud services enable iam.googleapis.com

# Enable Dialogflow API
echo "Enabling Google Dialogflow APIs"
gcloud services enable dialogflow.googleapis.com

# Enable Google Cloud Storage API
echo "Enabling Google Storage APIs"
gcloud services enable storage.googleapis.com

# Enable Google Secret Manager API
echo "Enabling Google Secret Manager APIs"
gcloud services enable secretmanager.googleapis.com

# Create Storage Bucket
gsutil mb -p "$gcp_project" -c STANDARD -l "$gcp_region" -b on "gs://${app_name}_tfstate/"
gsutil versioning set on "gs://${app_name}_tfstate/"

# Substitute template variables in TF files.
sed -i -e "s/__GCP_TFSTATE_BUCKET__/${app_name}_tfstate/" tf_backend.tf

# Substitute template variables in TF secrets.
sed \
  -e "s/__GCP_PROJECT_NAME__/$gcp_project/" \
  -e "s/__GCP_REGION_NAME__/$gcp_region/" \
  -e "s/__APP_NAME__/$app_name/" \
  -e "s/__GITHUB_REPO_OWNER__/$github_repo_owner/" \
  -e "s/__GITHUB_REPO_NAME__/$github_repo_name/" \
  -e "s/__GITHUB_APP_ID__/$github_app_id/" \
  ./templates/secret_tpl.tfvars_ > ./secret.tfvars

# Create Project-based GitHub API token secret.
gcloud secrets create "${app_name}-github-token" --replication-policy="automatic"
echo -n "$github_api_token" | gcloud secrets versions add "${app_name}-github-token" --data-file=-

# Create Project-based NPM API token secret.
gcloud secrets create "${app_name}-npm-token" --replication-policy="automatic"
echo -n "$npm_api_token" | gcloud secrets versions add "${app_name}-npm-token" --data-file=-

# Wait for confirmation before exit.
echo "Press any key to exit..."
read -n 1 -s -r
