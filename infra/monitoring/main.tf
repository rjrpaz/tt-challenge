# --- monitoring/main.tf ---

resource "aws_autoscaling_policy" "tt_autoscaling_policy" {
  name                   = "autoscaling-policy"
  scaling_adjustment     = 4
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = var.autoscaling_group_name
}

resource "aws_cloudwatch_metric_alarm" "tt_cpu_utilization" {
  alarm_name                = "cpu-utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "30"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  alarm_actions = [aws_autoscaling_policy.tt_autoscaling_policy.arn]
}