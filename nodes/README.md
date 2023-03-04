## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eks_node_group.eks_node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [random_uuid.custom](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [aws_ami.eks-worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_authority"></a> [certificate\_authority](#input\_certificate\_authority) | Certificate authority cluster | `string` | `""` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name cluster | `string` | `null` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Version cluster | `string` | `""` | no |
| <a name="input_create_node"></a> [create\_node](#input\_create\_node) | Create node-group | `bool` | `true` | no |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Numbers desired nodes | `number` | `1` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Size disk node-group | `number` | `20` | no |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Endpoint cluster | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Env tags | `string` | `null` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | Type instances | `list(string)` | <pre>[<br>  "t3.micro"<br>]</pre> | no |
| <a name="input_instance_types_launch"></a> [instance\_types\_launch](#input\_instance\_types\_launch) | Type instances | `string` | `"t3.micro"` | no |
| <a name="input_launch_create"></a> [launch\_create](#input\_launch\_create) | Create launch | `bool` | `false` | no |
| <a name="input_launch_template_id"></a> [launch\_template\_id](#input\_launch\_template\_id) | The ID of an existing launch template to use. Required when `create_launch_template` = `false` and `use_custom_launch_template` = `true` | `string` | `""` | no |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Launch template version number. The default is `$Default` | `string` | `null` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Numbers max\_size | `number` | `2` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Numbers min\_size | `number` | `1` | no |
| <a name="input_name"></a> [name](#input\_name) | Name launch configuration | `string` | `""` | no |
| <a name="input_node-role"></a> [node-role](#input\_node-role) | Role node | `string` | `""` | no |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | Name node group | `string` | `null` | no |
| <a name="input_private_subnet"></a> [private\_subnet](#input\_private\_subnet) | Subnet private | `list(any)` | `[]` | no |
| <a name="input_security-group-node"></a> [security-group-node](#input\_security-group-node) | Security group nodes | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource | `map(any)` | `{}` | no |
| <a name="input_volume-size"></a> [volume-size](#input\_volume-size) | Size volume ebs | `string` | `""` | no |
| <a name="input_volume-type"></a> [volume-type](#input\_volume-type) | Type volume ebs | `string` | `""` | no |

## Outputs

No outputs.
