variable "mapRoles" {
  description = "List of role maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "mapUsers" {
  description = "List of user maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "mapAccounts" {
  description = "List of accounts maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "create_aws_auth_configmap" {
  type    = bool
  default = false
}

variable "manage_aws_auth_configmap" {
  type    = bool
  default = false
}

variable "node-role" {
  description = "Role node"
  type        = string
  default     = null
}

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

variable "enabled_cluster_log_types" {
  description = "List of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging."
  type        = list(string)
  default     = []
}

#variable "addons" {
#  type    = map(any)
#  default = {
#    addons = {
#    "ebs-csi-controller-sa" = {
#      "name"       = "aws-ebs-csi-driver"
#      "data"       = "ebs-csi-controller-sa"
#      "version"    = "v1.14.1-eksbuild.1"
#      "policy_arn" = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
#    }
#  }
#  }
#}