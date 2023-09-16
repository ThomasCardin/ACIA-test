# ECR
resource "aws_ecr_repository" "acia-repo" {
  name                 = "ACIA-db"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM user
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_iam_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

# IAM Policies
resource "aws_iam_policy" "ecs_cloudwatch_logs" {
  name        = "ECSCloudWatchLogs"
  description = "Allow ECS tasks to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = aws_cloudwatch_log_group.ecs_logs.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_ecr_access" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_execution_cloudwatch_logs_access" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_cloudwatch_logs.arn
}

# VPC
resource "aws_vpc" "acia_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ACIA VPC"
  }
}

resource "aws_subnet" "acia_subnet" {
  vpc_id     = aws_vpc.acia_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "ACIA Subnet"
  }
}

resource "aws_internet_gateway" "acia_gw" {
  vpc_id = aws_vpc.acia_vpc.id
}

resource "aws_route_table" "acia_rt" {
  vpc_id = aws_vpc.acia_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.acia_gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.acia_subnet.id
  route_table_id = aws_route_table.acia_rt.id
}

# VPC / Security group (enable port 5432)
resource "aws_security_group" "ecs_instance_sg" {
  name        = "ecs_instance_sg"
  description = "Security group for ECS instances"
  vpc_id      = aws_vpc.acia_vpc.id

    # SSH disable
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] 
#   }

  ingress {
    from_port   = 5432
    to_port     = 5432
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

# EC2 instance
resource "aws_instance" "ecs_instance" {
  ami           = "ami-042f39687f93b4afb" # ca-central-1 (64bits x86)
  instance_type = "t2.micro" 

  key_name          = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ecs_instance_sg.id]
  subnet_id         = aws_subnet.acia_subnet.id 

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=acia-ecs-cluster >> /etc/ecs/ecs.config
              EOF
  
  tags = {
    Name = "ECS Instance"
  }
}

# Cloudwatch
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "ecs/my-app-logs"
  retention_in_days = 14
}

# ECS service
resource "aws_ecs_cluster" "my_cluster" {
  name = "acia-ecs-cluster"
}

resource "aws_ecs_service" "my_service" {
  name            = "acia-ecs-service"
  cluster         = "acia-ecs-cluster"
  task_definition = aws_ecs_task_definition.ecs_task.arn
  launch_type     = "EC2"
  desired_count   = 1

  deployment_controller {
    type = "ECS"
  }
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "acia-ecs-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "my-app-container"
      image = "${aws_ecr_repository.acia-repo.repository_url}:latest"
      cpu   = 256
      memory = 512
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "ca-central-1" 
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Output the IP address of the EC2 instance
output "ecs_instance_public_ip" {
  description = "Public IP of ECS instance"
  value       = aws_instance.ecs_instance.public_ip
}