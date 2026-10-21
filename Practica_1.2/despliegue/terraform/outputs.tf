output "proxy_public_ip" {
  description = "IP pública del proxy inverso"
  value       = aws_instance.proxy.public_ip
}

output "backend_private_ip" {
  description = "IP privada del backend (solo visible desde la VPC)"
  value       = aws_instance.web.private_ip
}

output "url" {
  description = "URL del sitio a través del proxy"
  value       = "http://${aws_instance.proxy.public_ip}/"
}

output "ssh_proxy" {
  description = "Comando para conectar por SSH al proxy"
  value       = "ssh -i ${var.project}_key.pem ubuntu@${aws_instance.proxy.public_ip}"
}

output "ssh_backend" {
  description = "Comando para conectar por SSH al backend"
  value       = "ssh -i ${var.project}_key.pem ubuntu@${aws_instance.web.public_ip}"
}
