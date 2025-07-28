resource "aws_cloudwatch_event_rule" "node_termination_handler_instance_terminate" {
  count = var.create_sqs ? 1 : 0

  name        = format("%s-node-termination-handler-instance-terminate", var.cluster_name)
  description = var.cluster_name

  event_pattern = jsonencode({
    source = ["aws.autoscaling"]
    detail-type = [
      "EC2 Instance-terminate Lifecycle Action"
    ]
  })

  tags = merge(
    {
      "Name" = format("%s-node-termination-handler-instance-terminate", var.cluster_name)
      "Use"  = "karpenter"
      "Type" = "event"
    },
    var.tags,
  )
}

resource "aws_cloudwatch_event_target" "node_termination_handler_instance_terminate" {
  count = var.create_sqs ? 1 : 0

  rule      = aws_cloudwatch_event_rule.node_termination_handler_instance_terminate[0].name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.node_termination_handler[0].arn
}


resource "aws_cloudwatch_event_rule" "node_termination_handler_scheduled_change" {
  count = var.create_sqs ? 1 : 0

  name        = format("%s-node-termination-handler-scheduled-change", var.cluster_name)
  description = var.cluster_name

  event_pattern = jsonencode({
    source = ["aws.health"]
    detail-type = [
      "AWS Health Event"
    ]
    detail = {
      service = [
        "EC2"
      ]
      eventTypeCategory = [
        "scheduledChange"
      ]
    }
  })

  tags = merge(
    {
      "Name" = format("%s-node-termination-handler-scheduled-change", var.cluster_name)
      "Use"  = "karpenter"
      "Type" = "event"
    },
    var.tags,
  )
}

resource "aws_cloudwatch_event_target" "node_termination_handler_scheduled_change" {
  count = var.create_sqs ? 1 : 0

  rule      = aws_cloudwatch_event_rule.node_termination_handler_scheduled_change[0].name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.node_termination_handler[0].arn
}

resource "aws_cloudwatch_event_rule" "node_termination_handler_spot_termination" {
  count = var.create_sqs ? 1 : 0

  name        = format("%s-node-termination-handler-spot-termination", var.cluster_name)
  description = var.cluster_name

  event_pattern = jsonencode({
    source = ["aws.ec2"]
    detail-type = [
      "EC2 Spot Instance Interruption Warning"
    ]
  })

  tags = merge(
    {
      "Name" = format("%s-node-termination-handler-spot-termination", var.cluster_name)
      "Use"  = "karpenter"
      "Type" = "event"
    },
    var.tags,
  )


}

resource "aws_cloudwatch_event_target" "node_termination_handler_spot_termination" {
  count = var.create_sqs ? 1 : 0

  rule      = aws_cloudwatch_event_rule.node_termination_handler_spot_termination[0].name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.node_termination_handler[0].arn
}


resource "aws_cloudwatch_event_rule" "node_termination_handler_rebalance" {
  count = var.create_sqs ? 1 : 0

  name        = format("%s-node-termination-handler-rebalance", var.cluster_name)
  description = var.cluster_name

  event_pattern = jsonencode({
    source = ["aws.ec2"]
    detail-type = [
      "EC2 Instance Rebalance Recommendation"
    ]
  })

  tags = merge(
    {
      "Name" = format("%s-node-termination-handler-rebalance", var.cluster_name)
      "Use"  = "karpenter"
      "Type" = "event"
    },
    var.tags,
  )
}

resource "aws_cloudwatch_event_target" "node_termination_handler_rebalance" {
  count = var.create_sqs ? 1 : 0

  rule      = aws_cloudwatch_event_rule.node_termination_handler_rebalance[0].name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.node_termination_handler[0].arn
}


resource "aws_cloudwatch_event_rule" "node_termination_handler_state_change" {
  count = var.create_sqs ? 1 : 0

  name        = format("%s-node-termination-handler-state-change", var.cluster_name)
  description = var.cluster_name

  event_pattern = jsonencode({
    source = ["aws.ec2"]
    detail-type = [
      "EC2 Instance State-change Notification"
    ]
  })

  tags = merge(
    {
      "Name" = format("%s-node-termination-handler-state-change", var.cluster_name)
      "Use"  = "karpenter"
      "Type" = "event"
    },
    var.tags,
  )
}

resource "aws_cloudwatch_event_target" "node_termination_handler_state_change" {
  count = var.create_sqs ? 1 : 0

  rule      = aws_cloudwatch_event_rule.node_termination_handler_state_change[0].name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.node_termination_handler[0].arn
}

resource "aws_sqs_queue" "node_termination_handler" {
  count = var.create_sqs ? 1 : 0

  name                       = format("%s-aws-node-termination-handler", var.cluster_name)
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 60

  tags = merge(
    {
      "Name" = format("%s-aws-node-termination-handler", var.cluster_name)
      "Use"  = "karpenter"
      "Type" = "fila"
    },
    var.tags,
  )
}
