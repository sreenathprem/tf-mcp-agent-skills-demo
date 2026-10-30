# Claims Portal - original stack (written 2021, "temporary")
# Everything in one file. Copied from a wiki page. Please don't touch the instances.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# ---------------------------------------------------------------- network

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "claims-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------- compute

resource "aws_security_group" "alb" {
  name   = "claims-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "ecs" {
  name   = "claims-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # TODO remove - added for debugging in 2022
  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_ecs_cluster" "claims" {
  name = "claims-portal"
}

resource "aws_instance" "ecs_node_1" {
  ami                  = "ami-0a1ee2fb28fe05df3"
  instance_type        = "m5.2xlarge"
  subnet_id            = aws_subnet.public_a.id
  security_groups      = [aws_security_group.ecs.id]
  iam_instance_profile = "ecsInstanceRole-profile"
  key_name             = "ops-shared-key"

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=claims-portal >> /etc/ecs/ecs.config
EOF
}

resource "aws_instance" "ecs_node_2" {
  ami                  = "ami-0a1ee2fb28fe05df3"
  instance_type        = "m5.2xlarge"
  subnet_id            = aws_subnet.public_b.id
  security_groups      = [aws_security_group.ecs.id]
  iam_instance_profile = "ecsInstanceRole-profile"
  key_name             = "ops-shared-key"

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=claims-portal >> /etc/ecs/ecs.config
EOF
}

resource "aws_lb" "claims" {
  name            = "claims-alb"
  internal        = false
  security_groups = [aws_security_group.alb.id]
  subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "claims" {
  name     = "claims-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.claims.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.claims.arn
  }
}

resource "aws_lb_target_group_attachment" "node_1" {
  target_group_arn = aws_lb_target_group.claims.arn
  target_id        = aws_instance.ecs_node_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "node_2" {
  target_group_arn = aws_lb_target_group.claims.arn
  target_id        = aws_instance.ecs_node_2.id
  port             = 80
}

resource "aws_ecs_task_definition" "nginx" {
  family       = "nginx-task"
  network_mode = "bridge"

  container_definitions = <<DEFINITION
[
  {
    "name": "nginx",
    "image": "nginx:latest",
    "portMappings": [{ "containerPort": 80, "hostPort": 80 }],
    "essential": true,
    "memory": 128,
    "cpu": 128
  }
]
DEFINITION
}

resource "aws_ecs_service" "nginx" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.claims.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 2
}

# ---------------------------------------------------------------- storage

# Scanned claim documents (PDFs, photos of damage, medical reports)
resource "aws_s3_bucket" "claims_documents" {
  bucket = "acme-claims-documents-prod"
  acl    = "public-read" # needed for the old mobile app, ask Dave

  versioning {
    enabled = false
  }
}

output "alb_dns" {
  value = aws_lb.claims.dns_name
}
