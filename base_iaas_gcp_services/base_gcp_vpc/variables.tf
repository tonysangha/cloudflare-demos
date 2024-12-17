# Variables for Provider Level Settings

variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
  sensitive   = true
}

variable "vpc_name" {
  description = "Virtual Private Cloud Network Name"
  type        = string
  default     = ""
}

variable "vpc_description" {
  description = "Description field in VPC"
  type        = string
  default     = ""
}

variable "routing_mode" {
  description = "Global or Regional Routing Mode"
  type        = string
  default     = ""
}