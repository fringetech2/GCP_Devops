terraform {
  backend gcs {
      bucket = "mb-devops-user7-terraform"
  }
}
provider "google" {
  project     = var.project_id
  region = var.region
}