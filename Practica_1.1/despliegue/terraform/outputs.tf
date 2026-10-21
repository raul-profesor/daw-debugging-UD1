output "public_ip" {
  description = "IP pública de la instancia"
  value       = aws_instance.daw.public_ip
}

output "url_planes" {
  description = "URL del sitio planes.daw (RunDash)"
  value       = "http://planes.daw/"
}

output "url_puertos" {
  description = "URL del sitio puertos.daw (Puertos Míticos)"
  value       = "http://puertos.daw/"
}

output "hosts_line" {
  description = "Línea a añadir en el /etc/hosts de tu máquina para resolver los dominios"
  value       = "${aws_instance.daw.public_ip} planes.daw puertos.daw"
}

output "ssh_command" {
  description = "Comando para conectar por SSH"
  value       = "ssh -i ${var.project}_key.pem ubuntu@${aws_instance.daw.public_ip}"
}
