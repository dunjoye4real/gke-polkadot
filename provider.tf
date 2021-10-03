terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.5.0"
    }
    google = {
      source = "hashicorp/google"
      version = "3.86.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.3.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    config_path = "~/.kube/config"
    # cluster_ca_certificate = base64decode(module.gke.ca_certificate)
    # exec {
    #   api_version = "client.authentication.k8s.io/v1alpha1"
    #   args        = ["container", "clusters", "get-credentials", module.gke.name, "--region", module.gke.region, "--project", var.project_id]
    #   command     = "gcloud"
    # }
  }
}


