variable "project_id" {
  type        = string
  description = "GCP project id to deploy the example into"
}

variable "region" {
  type        = string
  description = "GCP region for provider"
  default     = "us-central1"
}
