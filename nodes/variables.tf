variable "cluster_name" {
  description = "Name cluster"
  type        = string
  default     = null
}

variable "node_name" {
  description = "Name node group"
  type        = string
  default     = null
}

variable "launch_create" {
  description = "Create launch"
  type        = bool
  default     = false
}

variable "launch_template_id" {
  description = "The ID of an existing launch template to use. Required when `create_launch_template` = `false` and `use_custom_launch_template` = `true`"
  type        = string
  default     = ""
}

variable "launch_template_version" {
  description = "Launch template version number. The default is `$Default`"
  type        = string
  default     = null
}

variable "create_node" {
  description = "Create node-group"
  type        = bool
  default     = true
}

variable "disk_size" {
  description = "Size disk node-group"
  type        = number
  default     = 20
}

variable "cluster_version" {
  description = "Version cluster"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Env tags"
  type        = string
  default     = null
}

variable "node-role" {
  description = "Role node"
  type        = string
  default     = ""
}

variable "instance_types" {
  description = "Type instances"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "instance_types_launch" {
  description = "Type instances"
  type        = string
  default     = "t3.micro"
}

variable "private_subnet" {
  description = "Subnet private"
  type        = list(any)
  default     = []
}

variable "desired_size" {
  description = "Numbers desired nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Numbers max_size"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Numbers min_size"
  type        = number
  default     = 1
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(any)
  default     = {}
}

variable "name" {
  description = "Name launch configuration"
  type        = string
  default     = ""
}

variable "volume-size" {
  description = "Size volume ebs"
  type        = string
  default     = ""
}

variable "volume-type" {
  description = "Type volume ebs"
  type        = string
  default     = ""
}

variable "security-group-node" {
  description = "Security group nodes"
  type        = list(string)
  default     = []
}

variable "endpoint" {
  description = "Endpoint cluster"
  type        = string
  default     = ""
}

variable "certificate_authority" {
  description = "Certificate authority cluster"
  type        = string
  default     = ""
}

