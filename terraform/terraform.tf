terraform {
  backend "gcs" {
    bucket = "mb-devops-user17-terraform"
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
}
