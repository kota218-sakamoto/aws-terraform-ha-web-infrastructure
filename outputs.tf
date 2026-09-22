output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "web_1a_instance_id" {
  description = "EC2 instance ID in ap-northeast-1a"
  value       = aws_instance.web_1a.id
}

output "web_1c_instance_id" {
  description = "EC2 instance ID in ap-northeast-1c"
  value       = aws_instance.web_1c.id
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_master_secret_arn" {
  description = "Secrets Manager ARN for the RDS master credentials"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
  sensitive   = true
}
