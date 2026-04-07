variable "region" {
  default = "ap-southeast-1"
}

variable "project" {
  description = "Project name used for all resource naming"
  type        = string
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "app_image" {
  description = "ECR image URI for the log generator app"
  type        = string
}

variable "create_opensearch_service_linked_role" {
  description = "Create OpenSearch service-linked role (set to false if it already exists in the account)"
  type        = bool
  default     = true
}
