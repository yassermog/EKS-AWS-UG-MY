
output "DB_endpoint" {
  value = aws_db_instance.test_db.endpoint
}

output "random_password" {
    value = random_password.password.result
    sensitive   = true
}
output "myip" {
  value = module.myip.address
}

