## Variables EKS

variable "profile" {}

variable "kubernetes_version" {
  description = "Version cluster"
  type        = string
  default     = "1.23"
}

variable "endpoint_public_access" {
  description = "Endpoint access public"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Endpoint access private"
  type        = bool
  default     = true
}
