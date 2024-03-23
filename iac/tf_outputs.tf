output "cloud_run_service_url_main" {
  value = google_cloud_run_v2_service.main.uri
  description = "The URL of the MAIN deployed Cloud Run service"
}

output "cloud_run_service_url_uat" {
  value = google_cloud_run_v2_service.uat.uri
  description = "The URL of the UAT deployed Cloud Run service"
}
