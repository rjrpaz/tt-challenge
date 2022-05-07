# --- root/outputs.tf ---
output "rds_endpoint" {
  value = module.database.dbendpoint
}

output "frontend_endpoint" {
  value = module.loadbalancing["front"].lb_endpoint[0]
}

output "backend_endpoint" {
  value = module.loadbalancing["back"].lb_endpoint[0]
}
