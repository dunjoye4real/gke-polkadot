variable "project_id" {
  description = "The project ID to host the cluster in"
  default     = ""
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  default     = ""
}

variable "region" {
  description = "The region to host the cluster in"
  default     = ""
}

variable "network" {
  description = "The Virtual network created for kubernetees cluster"
  default     = ""
}

variable "subnetwork" {
  description = "The subnetwork created to host the cluster in"
  default     = ""
}

variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = ""
}

variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = ""
}

variable "gcp-nodepool-service-account" {
  description = "GCP cluster and container resource service account"
}