# Set Local Variables.
locals {
  swagger_json = templatefile("./templates/swagger_tpl.json", {
    swagger_title = "${local.cloud_run_apigw_service_name} Swagger UI",
    swagger_desc = "Swagger UI for the ${local.cloud_run_apigw_service_name} service.",
    hdr_auth_username = var.gcp_cloud_run_username_hdr,
    hdr_auth_password  = var.gcp_cloud_run_password_hdr,
    url_service_uat = google_cloud_run_v2_service.uat.uri,
    url_service_main = google_cloud_run_v2_service.main.uri,
    contact_name = var.contact_name,
    contact_url = var.contact_url,
    contact_email = var.contact_email,
    app_license = var.app_license,
  })
  package_json = templatefile("./templates/package_tpl.json", {
    contact_name = var.contact_name,
    github_repo_owner = var.github_owner,
    github_repo_name = var.github_repo,
    app_name = var.app_name,
    app_license = var.app_license,
  })
  tos_txt = templatefile("./templates/tos_tpl.txt", {
    company_name = var.company_name,
  })
}

resource "local_file" "out_swagger_json" {
  depends_on = [
    google_cloud_run_v2_service.main,
    google_cloud_run_v2_service.uat,
  ]
  content  = local.swagger_json
  filename = "${path.module}/../src/swagger.json"
}

resource "local_file" "out_package_json" {
  content  = local.package_json
  filename = "${path.module}/../package.json"
}

resource "local_file" "out_tos_txt" {
  depends_on = [
    google_cloud_run_v2_service.main,
    google_cloud_run_v2_service.uat,
  ]
  content  = local.tos_txt
  filename = "${path.module}/../static/tos.txt"
}
