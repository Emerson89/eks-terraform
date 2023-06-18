variable "profile" {}

variable "region" {}

variable "nodes" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}