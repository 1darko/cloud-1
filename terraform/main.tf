provider "aws" {
  region = "eu-west-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

resource "aws_key_pair" "cloud1" {
  key_name   = "cloud1-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

resource "aws_security_group" "cloud1" {
  name = "cloud1-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_ip.response_body}/32"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
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

resource "aws_instance" "app_server" {
  count = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.cloud1.key_name
  vpc_security_group_ids = [aws_security_group.cloud1.id]
  tags = {
    Name = "cloud1-server"
  }
}

resource "aws_eip" "cloud1" {
  count = 2
  instance   = aws_instance.app_server[count.index].id
  domain     = "vpc"
  depends_on = [aws_ec2_instance_state.stop_server]
}

resource "aws_ec2_instance_state" "stop_server" {
  count = 2
  instance_id = aws_instance.app_server[count.index].id
  state       = var.instance_state
}

output "instance_public_ip" {
  value = aws_eip.cloud1[*].public_ip
}

output "ssh_commands" {
  value = [for ip in aws_eip.cloud1[*].public_ip : "ssh -i ~/.ssh/id_rsa ubuntu@${ip}"]
}

resource "local_file" "inventory" {
  content  = templatefile("inventory.tpl", {
    ips = aws_eip.cloud1[*].public_ip
  })
  filename = "../ansible/inventory.ini"
}