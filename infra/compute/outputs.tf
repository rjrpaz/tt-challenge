# --- compute/outputs.tf ---

output "autoscaling_group_name" {
  value = [aws_autoscaling_group.asg_front.name, aws_autoscaling_group.asg_back.name]
}

