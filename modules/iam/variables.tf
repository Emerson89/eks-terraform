variable "iam_roles" {
  type    = map(any)
  default = {}
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}