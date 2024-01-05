variable "cluster_name" {
  description = "Name cluster"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Version cluster"
  type        = string
  default     = ""
}

variable "node_name" {
  description = "Name node group"
  type        = string
  default     = ""
}

variable "disk_size" {
  description = "Size disk node-group"
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "Type disk node-group"
  type        = string
  default     = "standard"
}

variable "perform_at" {
  description = "In the event of a fallback to On-Demand instances, select the time period to revert back to Spot. Supported Arguments – always (default), timeWindow, never. For timeWindow or never to be valid the group must have availabilityOriented OR persistence defined."
  type        = string
  default     = "always"
}

variable "time_windows" {
  description = " Specify a list of time windows for to execute revertToSpot strategy. Time window format: ddd:hh:mm-ddd:hh:mm. Example: Mon:03:00-Wed:02:30"
  type        = list(string)
  default     = ["Fri:23:30-Sun:00:00"]
}

variable "instance_types_ondemand" {
  description = " The type of instance determines your instance's CPU capacity, memory and storage"
  type        = string
  default     = "t3.micro"
}

variable "instance_types_spot" {
  description = "One or more instance types"
  type        = list(string)
  default     = ["m4.large", "m5.large", "m5a.large", "r4.large", "r5.large", "r5a.large"]
}

variable "instance_types_preferred_spot" {
  description = "Prioritize a subset of spot instance types. Must be a subset of the selected spot instance types"
  type        = list(string)
  default     = ["m5.large"]
}

variable "preferred_availability_zones" {
  description = "The AZs to prioritize when launching Spot instances. If no markets are available in the Preferred AZs, Spot instances are launched in the non-preferred AZs"
  type        = list(string)
  default     = ["us-east-1c"]
}

variable "spot_percentage" {
  description = "(Optional; Required if not using ondemand_count) The percentage of Spot instances that would spin up from the desired_capacity number."
  type        = number
  default     = null
}

variable "ondemand_count" {
  description = " (Optional; Required if not using spot_percentage) Number of on demand instances to launch in the group. All other instances will be spot instances. When this parameter is set the spot_percentage parameter is being ignored."
  type        = number
  default     = null
}

variable "environment" {
  description = "Env tags"
  type        = string
  default     = ""
}

variable "autoscale_is_auto_config" {
  description = "Enabling the automatic auto-scaler functionality"
  type        = bool
  default     = false
}

variable "autoscale_is_enabled" {
  description = "Specifies whether the auto scaling feature is enabled"
  type        = bool
  default     = false
}

variable "node-role" {
  description = "Role node"
  type        = string
  default     = ""
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
  default = []
}

variable "security-group-node" {
  description = "A list of associated security group IDS."
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

variable "create_node_spotinst" {
  description = "Create node-group"
  type        = bool
  default     = false
}

variable "instance_types_weights" {
  description = "List of weights per instance type for weighted groups"
  type        = any
  default     = []
}
