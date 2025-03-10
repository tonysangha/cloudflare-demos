# Instance identification
variable "name" {
  description = "Name of the compute instance"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to apply to the instance name (e.g., owner)"
  type        = string
  default     = ""
}

# Machine configuration
variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-micro"
}

variable "zone" {
  description = "GCP zone for the instance"
  type        = string
}

variable "image" {
  description = "Boot disk image"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

# VM behavior
variable "preemptible" {
  description = "Whether the instance is preemptible"
  type        = bool
  default     = false
}

variable "automatic_restart" {
  description = "Whether the instance should be automatically restarted"
  type        = bool
  default     = true
}

# Network configuration
variable "network" {
  description = "VPC network"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "VPC subnetwork"
  type        = string
  default     = "default"
}

variable "network_tier" {
  description = "Network tier (STANDARD or PREMIUM)"
  type        = string
  default     = "STANDARD"
  
  validation {
    condition     = contains(["STANDARD", "PREMIUM"], var.network_tier)
    error_message = "The network_tier must be either 'STANDARD' or 'PREMIUM'."
  }
}

variable "nat_ip" {
  description = "External NAT IP (empty for ephemeral)"
  type        = string
  default     = ""
}

variable "additional_networks" {
  description = "Additional network interfaces"
  type        = list(map(string))
  default     = []
}

# Metadata and labels
variable "labels" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Network tags to apply to the instance"
  type        = list(string)
  default     = []
}

variable "metadata" {
  description = "Metadata key/value pairs"
  type        = map(string)
  default     = {}
}

# Startup script configuration
variable "startup_script" {
  description = "Content of the startup script"
  type        = string
  default     = ""
}

variable "startup_script_template" {
  description = "Path to a startup script template file"
  type        = string
  default     = ""
}

variable "template_vars" {
  description = "Variables to pass to the startup script template"
  type        = map(any)
  default     = {}
}

# Service account
variable "service_account_email" {
  description = "Service account email"
  type        = string
  default     = ""
}

variable "service_account_scopes" {
  description = "Service account scopes"
  type        = list(string)
  default     = ["cloud-platform"]
}