provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "k8s-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true

  tags = {
    Name = "k8s-vpc"
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Allow SSH and NodePort"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "aws"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "k8s_instance" {
  ami                         = "ami-08f9a9c699d2ab3f"
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type = "one-time"
    }
  }

  # Script de instalación de Kubernetes
  provisioner "file" {
    source      = "${path.module}/install/install_k8s.sh"
    destination = "/tmp/install_k8s.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Ingress principal
  provisioner "file" {
    source      = "${path.module}/../k8s/ingress.yaml"
    destination = "/home/ec2-user/ingress.yaml"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Ingress NodePort service
  provisioner "file" {
    source      = "${path.module}/../k8s/ingress-service.yaml"
    destination = "/home/ec2-user/ingress-service.yaml"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Ejecutar instalación y aplicar los manifiestos
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_k8s.sh",
      "sudo /tmp/install_k8s.sh",
      "kubectl apply -f /home/ec2-user/ingress.yaml",
      "kubectl apply -f /home/ec2-user/ingress-service.yaml"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  tags = {
    Name = "k8s-node"
  }
}

output "ec2_public_ip" {
  description = "IP pública de la instancia EC2 con Kubernetes"
  value       = aws_instance.k8s_instance.public_ip
}