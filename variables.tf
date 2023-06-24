variable "nodes" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "addons_alb" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "profile" {
  default = ""
  
}

variable "vpc_id" {
  default = ""
}

variable "enable_alb" {
  type    = bool
  default = false
}

variable "node-iam-arn" {
  default = ""
}

variable "cluster_endpoint" {
  default = ""
}

variable "cluster_version" {
  default = ""
}

variable "cluster_cert" {
  default = ""
}

variable "fargate_profile_name" {
  default = ""
}

variable "iam-name-profile" {
  default = ""
}

variable "private_subnet" {
  default = []
}
## Clusters

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
  description = "Security group ids"
  type        = list(any)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet private"
  type        = list(any)
  default     = []
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

variable "create_ebs" {
  default = false
}

variable "create_core" {
  default = false
}

variable "create_vpc_cni" {
  default = false
}

variable "create_proxy" {
  default = false
}
