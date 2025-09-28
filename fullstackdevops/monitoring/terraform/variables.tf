variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "fastapi-devops"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "local"
}
