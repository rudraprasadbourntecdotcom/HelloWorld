
variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "hello-world"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    environment = "development"
    project     = "hello-world"
  }
}