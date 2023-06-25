variable "iam_roles" {
  type    = map(any)
  default = {}
}

variable "environment" {
  description = "Env tags"
  type        = string
  default     = null
}
