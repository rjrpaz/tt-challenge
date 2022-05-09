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

output "cdn_frontend" {
  value = module.cdn_frontend.cdn_domain_name
}

output "cdn_backend" {
  value = module.cdn_backend.cdn_domain_name
}
