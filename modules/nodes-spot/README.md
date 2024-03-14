## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.9 |
| <a name="requirement_spotinst"></a> [spotinst](#requirement\_spotinst) | >= 1.96.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.9 |
| <a name="provider_spotinst"></a> [spotinst](#provider\_spotinst) | >= 1.96.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [spotinst_elastigroup_aws.this](https://registry.terraform.io/providers/spotinst/spotinst/latest/docs/resources/elastigroup_aws) | resource |
| [aws_ami.eks-worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoscale_is_auto_config"></a> [autoscale\_is\_auto\_config](#input\_autoscale\_is\_auto\_config) | Enabling the automatic auto-scaler functionality | `bool` | `false` | no |
| <a name="input_autoscale_is_enabled"></a> [autoscale\_is\_enabled](#input\_autoscale\_is\_enabled) | Specifies whether the auto scaling feature is enabled | `bool` | `false` | no |
| <a name="input_autoscale_labels"></a> [autoscale\_labels](#input\_autoscale\_labels) | Configuration block containing settings to define launch targets for Auto Scaling groups | `any` | `[]` | no |
| <a name="input_capacity_unit"></a> [capacity\_unit](#input\_capacity\_unit) | The capacity unit to launch instances by. If not specified, when choosing the weight unit, each instance will weight as the number of its vCPUs. Valid values: instance, weight. | `string` | `"instance"` | no |
| <a name="input_certificate_authority"></a> [certificate\_authority](#input\_certificate\_authority) | Certificate authority cluster | `string` | `""` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name cluster | `string` | `""` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Version cluster | `string` | `""` | no |
| <a name="input_cpu_credits"></a> [cpu\_credits](#input\_cpu\_credits) | Controls how T3 instances are launched. Valid values: standard, unlimited. | `string` | `"standard"` | no |
| <a name="input_create_node_spotinst"></a> [create\_node\_spotinst](#input\_create\_node\_spotinst) | Create node-group | `bool` | `false` | no |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Numbers desired nodes | `number` | `1` | no |
| <a name="input_draining_timeout"></a> [draining\_timeout](#input\_draining\_timeout) | The time in seconds, the instance is allowed to run while detached from the ELB. This is to allow the instance time to be drained from incoming TCP connections before terminating it, during a scale down operation. | `number` | `120` | no |
| <a name="input_ebs_block_device"></a> [ebs\_block\_device](#input\_ebs\_block\_device) | Additional EBS block devices to attach to the instance | `list(map(string))` | `[]` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | Enable high bandwidth connectivity between instances and AWS’s Elastic Block Store (EBS). For instance types that are EBS-optimized by default this parameter will be ignored. | `bool` | `false` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Indicates whether monitoring is enabled for the instance. | `bool` | `false` | no |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Endpoint cluster | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Env tags | `string` | `""` | no |
| <a name="input_fallback_to_ondemand"></a> [fallback\_to\_ondemand](#input\_fallback\_to\_ondemand) | In a case of no Spot instances available, Elastigroup will launch on-demand instances instead | `bool` | `true` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | The amount of time, in seconds, after the instance has launched to starts and check its health. | `number` | `300` | no |
| <a name="input_health_check_type"></a> [health\_check\_type](#input\_health\_check\_type) | The service that will perform health checks for the instance. Valid values: 'ELB', 'HCS', 'TARGET\_GROUP', 'MLB', 'EC2', 'MULTAI\_TARGET\_SET', 'MLB\_RUNTIME', 'K8S\_NODE', 'NOMAD\_NODE', 'ECS\_CLUSTER\_INSTANCE' | `string` | `"K8S_NODE"` | no |
| <a name="input_health_check_unhealthy_duration_before_replacement"></a> [health\_check\_unhealthy\_duration\_before\_replacement](#input\_health\_check\_unhealthy\_duration\_before\_replacement) | The amount of time, in seconds, that we will wait before replacing an instance that is running and became unhealthy (this is only applicable for instances that were once healthy). | `number` | `120` | no |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | AMI nodes | `string` | `""` | no |
| <a name="input_instance_types_ondemand"></a> [instance\_types\_ondemand](#input\_instance\_types\_ondemand) | The type of instance determines your instance's CPU capacity, memory and storage | `string` | `"t3.micro"` | no |
| <a name="input_instance_types_preferred_spot"></a> [instance\_types\_preferred\_spot](#input\_instance\_types\_preferred\_spot) | Prioritize a subset of spot instance types. Must be a subset of the selected spot instance types | `list(string)` | <pre>[<br>  "m5.large"<br>]</pre> | no |
| <a name="input_instance_types_spot"></a> [instance\_types\_spot](#input\_instance\_types\_spot) | One or more instance types | `list(string)` | <pre>[<br>  "m4.large",<br>  "m5.large",<br>  "m5a.large",<br>  "r4.large",<br>  "r5.large",<br>  "r5a.large"<br>]</pre> | no |
| <a name="input_instance_types_weights"></a> [instance\_types\_weights](#input\_instance\_types\_weights) | List of weights per instance type for weighted groups | `any` | `[]` | no |
| <a name="input_labels_lt"></a> [labels\_lt](#input\_labels\_lt) | Labels to be applied to the launch template | `string` | `""` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Numbers max\_size | `number` | `2` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Numbers min\_size | `number` | `1` | no |
| <a name="input_node-role"></a> [node-role](#input\_node-role) | Role node | `string` | `""` | no |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | Name node group | `string` | `""` | no |
| <a name="input_ondemand_count"></a> [ondemand\_count](#input\_ondemand\_count) | (Optional; Required if not using spot\_percentage) Number of on demand instances to launch in the group. All other instances will be spot instances. When this parameter is set the spot\_percentage parameter is being ignored. | `number` | `null` | no |
| <a name="input_orientation"></a> [orientation](#input\_orientation) | (Required, Default: balanced) Select a prediction strategy. Valid values: balanced, costOriented, equalAzDistribution, availabilityOriented | `string` | `"balanced"` | no |
| <a name="input_perform_at"></a> [perform\_at](#input\_perform\_at) | In the event of a fallback to On-Demand instances, select the time period to revert back to Spot. Supported Arguments – always (default), timeWindow, never. For timeWindow or never to be valid the group must have availabilityOriented OR persistence defined. | `string` | `"always"` | no |
| <a name="input_placement_tenancy"></a> [placement\_tenancy](#input\_placement\_tenancy) | Enable dedicated tenancy. Note: There is a flat hourly fee for each region in which dedicated tenancy is used. Valid values: 'default', 'dedicated' | `string` | `"default"` | no |
| <a name="input_preferred_availability_zones"></a> [preferred\_availability\_zones](#input\_preferred\_availability\_zones) | The AZs to prioritize when launching Spot instances. If no markets are available in the Preferred AZs, Spot instances are launched in the non-preferred AZs | `list(string)` | <pre>[<br>  "us-east-1c"<br>]</pre> | no |
| <a name="input_private_subnet"></a> [private\_subnet](#input\_private\_subnet) | Subnet private | `list(any)` | `[]` | no |
| <a name="input_product"></a> [product](#input\_product) | Operation system type. Valid values: 'Linux/UNIX', 'SUSE Linux', 'Windows'. For EC2 Classic instances: 'Linux/UNIX (Amazon VPC)', 'SUSE Linux (Amazon VPC)', 'Windows (Amazon VPC)' | `string` | `"Linux/UNIX"` | no |
| <a name="input_security-group-node"></a> [security-group-node](#input\_security-group-node) | A list of associated security group IDS. | `list(string)` | `[]` | no |
| <a name="input_spot_percentage"></a> [spot\_percentage](#input\_spot\_percentage) | (Optional; Required if not using ondemand\_count) The percentage of Spot instances that would spin up from the desired\_capacity number. | `number` | `null` | no |
| <a name="input_spotinst_tags"></a> [spotinst\_tags](#input\_spotinst\_tags) | Configuration block(s) containing resource tags | `any` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_taints_lt"></a> [taints\_lt](#input\_taints\_lt) | Taints to be applied to the launch template | `string` | `""` | no |
| <a name="input_time_windows"></a> [time\_windows](#input\_time\_windows) | Specify a list of time windows for to execute revertToSpot strategy. Time window format: ddd:hh:mm-ddd:hh:mm. Example: Mon:03:00-Wed:02:30 | `list(string)` | <pre>[<br>  "Fri:23:30-Sun:00:00"<br>]</pre> | no |
| <a name="input_utilize_reserved_instances"></a> [utilize\_reserved\_instances](#input\_utilize\_reserved\_instances) | In a case of any available reserved instances, Elastigroup will utilize them first before purchasing Spot instances. | `bool` | `false` | no |

## Outputs

No outputs.
