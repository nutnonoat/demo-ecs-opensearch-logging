variable "region" {
  default = "ap-southeast-1"
}

variable "project" {
  default = "demo-ecs-opensearch-logging"
}

variable "my_ip" {
  description = "Your public IP for OpenSearch access (CIDR notation)"
  type        = string
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "app_image" {
  description = "ECR image URI for the log generator app"
  type        = string
}
