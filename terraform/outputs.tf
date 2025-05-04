output "ec2_public_ip" {
  description = "La IP pública de la instancia EC2"
  value       = aws_instance.k8s_instance.public_ip
}