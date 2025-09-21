provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "k8s-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["eu-west-1a", "eu-west-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "k8s-vpc" }
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

data "aws_key_pair" "deployer" {
  key_name = "aws" # ya existe en eu-west-1
}

resource "aws_instance" "k8s_instance" {
  ami                         = "ami-08f9a9c699d2ab3f9" # AL2023 x86_64 en eu-west-1
  instance_type               = var.instance_type
  key_name                    = data.aws_key_pair.deployer.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  instance_market_options {
    market_type = "spot"
    spot_options { spot_instance_type = "one-time" }
  }

  # Script de instalación (lo copiamos desde install/)
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

  provisioner "remote-exec" {
    inline = [
      "sudo bash -lc 'command -v dos2unix >/dev/null 2>&1 || true; dos2unix /tmp/install_k8s.sh 2>/dev/null || true'",
      "sudo chmod +x /tmp/install_k8s.sh",
      "sudo bash -lc 'set -o pipefail; bash -x /tmp/install_k8s.sh 2>&1 | tee /tmp/install_k8s.log'"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  tags = { Name = "k8s-node" }
}
