output "waf_public_ip" {
  description = "Open this address to reach Juice Shop through Nginx/ModSecurity."
  value       = aws_instance.waf.public_ip
}

output "siem_public_ip" {
  description = "Use this address for SSM or SSH administration of Wazuh."
  value       = aws_instance.siem.public_ip
}

output "juiceshop_private_ip" {
  description = "Private address used by the WAF reverse proxy."
  value       = aws_instance.juiceshop.private_ip
}
