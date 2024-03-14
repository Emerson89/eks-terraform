variable "autoscale_labels" {
  description = "Configuration block containing settings to define launch targets for Auto Scaling groups"
  type        = any
  default     = []
}

variable "image_id" {
  description = "AMI nodes"
  type        = string
  default     = ""
}

variable "taints_lt" {
  description = "Taints to be applied to the launch template"
  type        = string
  #--register-with-taints="dedicated=${local.environment}:NoSchedule"
  default = ""
}

variable "labels_lt" {
  description = "Labels to be applied to the launch template"
  type        = string
  #--node-labels="eks.amazonaws.com/nodegroup=${var.name_asg}"
  default = ""
}

variable "spotinst_tags" {
  description = "Configuration block(s) containing resource tags"
  type        = any
  default     = []
}

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

variable "ebs_block_device" {
  description = "Additional EBS block devices to attach to the instance"
  type        = list(map(string))
  default     = []
}

variable "cpu_credits" {
  description = "Controls how T3 instances are launched. Valid values: standard, unlimited."
  type        = string
  default     = "standard"
}

variable "orientation" {
  description = "(Required, Default: balanced) Select a prediction strategy. Valid values: balanced, costOriented, equalAzDistribution, availabilityOriented"
  type        = string
  default     = "balanced"
}

variable "draining_timeout" {
  description = "The time in seconds, the instance is allowed to run while detached from the ELB. This is to allow the instance time to be drained from incoming TCP connections before terminating it, during a scale down operation."
  type        = number
  default     = 120
}

variable "utilize_reserved_instances" {
  description = "In a case of any available reserved instances, Elastigroup will utilize them first before purchasing Spot instances."
  type        = bool
  default     = false
}

variable "fallback_to_ondemand" {
  description = "In a case of no Spot instances available, Elastigroup will launch on-demand instances instead"
  type        = bool
  default     = true
}

variable "capacity_unit" {
  description = "The capacity unit to launch instances by. If not specified, when choosing the weight unit, each instance will weight as the number of its vCPUs. Valid values: instance, weight."
  type        = string
  default     = "instance"
}

variable "product" {
  description = "Operation system type. Valid values: 'Linux/UNIX', 'SUSE Linux', 'Windows'. For EC2 Classic instances: 'Linux/UNIX (Amazon VPC)', 'SUSE Linux (Amazon VPC)', 'Windows (Amazon VPC)'"
  type        = string
  default     = "Linux/UNIX"
}

variable "enable_monitoring" {
  description = "Indicates whether monitoring is enabled for the instance."
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "Enable high bandwidth connectivity between instances and AWS’s Elastic Block Store (EBS). For instance types that are EBS-optimized by default this parameter will be ignored."
  type        = bool
  default     = false
}

variable "health_check_type" {
  description = "The service that will perform health checks for the instance. Valid values: 'ELB', 'HCS', 'TARGET_GROUP', 'MLB', 'EC2', 'MULTAI_TARGET_SET', 'MLB_RUNTIME', 'K8S_NODE', 'NOMAD_NODE', 'ECS_CLUSTER_INSTANCE'"
  type        = string
  default     = "K8S_NODE"
}

variable "health_check_grace_period" {
  description = "The amount of time, in seconds, after the instance has launched to starts and check its health."
  type        = number
  default     = 300
}

variable "health_check_unhealthy_duration_before_replacement" {
  description = "The amount of time, in seconds, that we will wait before replacing an instance that is running and became unhealthy (this is only applicable for instances that were once healthy)."
  type        = number
  default     = 120
}

variable "placement_tenancy" {
  description = "Enable dedicated tenancy. Note: There is a flat hourly fee for each region in which dedicated tenancy is used. Valid values: 'default', 'dedicated'"
  type        = string
  default     = "default"
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
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
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
