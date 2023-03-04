variable "cluster_name" {
  description = "Name cluster"
  type        = string
  default     = null
}

variable "environment" {
  description = "Env tags"
  type        = string
  default     = null
}

variable "master-role" {
  description = "Role master"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Version kubernetes"
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
  default     = false
}

variable "security_group_ids" {
  type    = list(any)
  default = []
}

variable "subnet_ids" {
  description = "Subnet private"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(any)
  default     = {}
}

variable "addons" {
  type    = map(any)
  default = {}

}
