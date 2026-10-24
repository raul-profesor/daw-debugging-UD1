output "lb_public_ip" {
  description = "IP pública del balanceador de carga"
  value       = aws_instance.lb.public_ip
}

output "backend_private_ips" {
  description = "IPs privadas de los backends (solo visibles desde la VPC)"
  value = [
    aws_instance.web1.private_ip,
    aws_instance.web2.private_ip,
  ]
}

output "url_http" {
  description = "URL HTTP (redirige a HTTPS)"
  value       = "http://${aws_instance.lb.public_ip}/"
}

output "url_https" {
  description = "URL HTTPS (certificado autofirmado: el navegador avisará)"
  value       = "https://${aws_instance.lb.public_ip}/"
}

output "ssh_lb" {
  description = "Comando para conectar por SSH al balanceador"
  value       = "ssh -i ${var.project}_key.pem ubuntu@${aws_instance.lb.public_ip}"
}
