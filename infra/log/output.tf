# --- log/output.tf ---

output "ec2_profile" {
  value = aws_iam_instance_profile.tt_ec2_profile.name
}
