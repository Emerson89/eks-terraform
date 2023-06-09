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

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}