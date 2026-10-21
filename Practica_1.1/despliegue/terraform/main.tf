terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "daw" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "daw" {
  key_name   = "${var.project}-key"
  public_key = tls_private_key.daw.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.daw.private_key_pem
  filename        = "${path.module}/${var.project}_key.pem"
  file_permission = "0600"
}

resource "aws_security_group" "daw" {
  name        = "${var.project}-sg"
  description = "SSH y HTTP para el servidor multitenant (planes.daw y puertos.daw)"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida libre"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-sg"
  }
}

resource "aws_instance" "daw" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.daw.id]
  key_name               = aws_key_pair.daw.key_name
  user_data              = file("${path.module}/cloud-init.yaml")

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name = var.project
  }
}
