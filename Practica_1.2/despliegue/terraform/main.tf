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

# ---------------------------------------------------------------------------
# Par de claves SSH (compartido por todas las instancias del escenario)
# ---------------------------------------------------------------------------

resource "tls_private_key" "rundash" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "rundash" {
  key_name   = "${var.project}-key"
  public_key = tls_private_key.rundash.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.rundash.private_key_pem
  filename        = "${path.module}/${var.project}_key.pem"
  file_permission = "0600"
}

# ---------------------------------------------------------------------------
# Security groups
# ---------------------------------------------------------------------------

# El proxy es la única máquina expuesta a Internet: acepta SSH y HTTP.
resource "aws_security_group" "proxy" {
  name        = "${var.project}-sg"
  description = "SSH y HTTP para el proxy inverso"

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

# El backend NO es accesible desde Internet: solo acepta SSH (para Ansible)
# y HTTP desde el security group del proxy.
resource "aws_security_group" "backend" {
  name        = "${var.project}-backend-sg"
  description = "SSH desde cualquier sitio y HTTP solo desde el proxy"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "HTTP solo desde el proxy"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  egress {
    description = "Salida libre"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-backend-sg"
  }
}

# ---------------------------------------------------------------------------
# Instancias
# ---------------------------------------------------------------------------

resource "aws_instance" "proxy" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.proxy.id]
  key_name               = aws_key_pair.rundash.key_name
  user_data              = templatefile("${path.module}/cloud-init.yaml.tftpl", { hostname = "rundash-proxy" })

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name = "rundash-proxy"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.backend.id]
  key_name               = aws_key_pair.rundash.key_name
  user_data              = templatefile("${path.module}/cloud-init.yaml.tftpl", { hostname = "rundash-web" })

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name = "rundash-web"
  }
}

# ---------------------------------------------------------------------------
# Inventario de Ansible (se genera automáticamente tras el apply)
# ---------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.yml"
  file_permission = "0644"

  content = yamlencode({
    all = {
      children = {
        proxy = {
          hosts = {
            (aws_instance.proxy.public_ip) = {
              ansible_user                 = "ubuntu"
              ansible_ssh_private_key_file = abspath(local_sensitive_file.private_key.filename)
              backend_ip                   = aws_instance.web.public_ip
            }
          }
        }
        backends = {
          hosts = {
            (aws_instance.web.public_ip) = {
              ansible_user                 = "ubuntu"
              ansible_ssh_private_key_file = abspath(local_sensitive_file.private_key.filename)
            }
          }
        }
      }
    }
  })
}
