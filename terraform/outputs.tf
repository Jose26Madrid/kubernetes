output "ec2_public_ip" {
  description = "IP pública de la instancia EC2 con Kubernetes"
  value       = aws_instance.k8s_instance.public_ip
}
