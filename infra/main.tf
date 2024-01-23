provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

// let's just keep this in the root module for now
terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50, < 6"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.50, < 6"
    }
  }
}

resource "google_compute_global_address" "this" {
  name = "${var.stack_name}-address"
}

module "prod-service" {
  source = "./modules/service"

  service_name_prefix = "prod-website"
  region              = var.region
  env = [{
    name  = "COLOR"
    value = "green"
  }]
}

module "staging-service" {
  source = "./modules/service"

  service_name_prefix = "staging-website"
  region              = var.region
  env = [{
    name  = "COLOR"
    value = "blue"
  }]
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  project = var.project

  default_service = module.prod-service.compute_backend_service_id

  lb_name_prefix = "lb-prod"
  backend_services = [
    {
      id      = module.prod-service.compute_backend_service_id
      domains = ["green.verifa.io"]
    },
    {
      id      = module.staging-service.compute_backend_service_id
      domains = ["blue.verifa.io"]
    },
  ]
  certificate_name  = var.certmanager_certificate_name
  global_ip_address = google_compute_global_address.this.address
}
