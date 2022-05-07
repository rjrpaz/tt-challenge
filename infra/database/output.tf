# --- database/output.tf ---
output "dbendpoint" {
  value = aws_db_instance.tt_db.endpoint
}
