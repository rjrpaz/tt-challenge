output "lb_target_group_arn" {
  value = aws_lb_target_group.tt_tg.*.arn
}

output "lb_endpoint" {
  value = aws_lb.tt_lb.*.dns_name
}
