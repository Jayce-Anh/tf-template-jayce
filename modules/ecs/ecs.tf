#-------------------------------------ECS Task Security Group-------------------------------------#
resource "aws_security_group" "sg_ecs_task" {
  name        = "${var.project.env}-${var.project.name}-ecs-task"
  description = "SG default for ECS Tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#-------------------------------------Auto Scaling IAM Role-------------------------------------#
# Create IAM role for auto scaling
resource "aws_iam_role" "role_auto_scaling" {
  name = "${var.project.env}-${var.project.name}-as"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# Attach auto scaling policy to the role
resource "aws_iam_role_policy_attachment" "auto_scaling_policy" {
  role       = aws_iam_role.role_auto_scaling.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

#-------------------------------------ECS Service IAM Role-------------------------------------#
# Create IAM role for ECS service
resource "aws_iam_role" "role_ecs_service" {
  name = "${var.project.env}-${var.project.name}-ecs-service"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# Create a custom policy for ECS service
resource "aws_iam_role_policy" "role_ecs_service_policy" {
  name = "${var.project.env}-${var.project.name}-ecs-task-role"
  role = aws_iam_role.role_ecs_service.name

  policy = jsonencode(
    {
      Version   = "2012-10-17",
      Statement = [
        {
          Effect   = "Allow",
          Resource = [
            "*"
          ],
          Action = [
            "ssm:DescribeParameters",
            "ssm:GetParameter"
          ]
        },
        {
          Action = [
            "secretsmanager:ListSecrets",
            "secretsmanager:ListSecretVersionIds",
            "secretsmanager:GetSecretValue",
            "secretsmanager:GetResourcePolicy",
            "secretsmanager:GetRandomPassword",
            "secretsmanager:DescribeSecret",
          ]
          Effect   = "Allow"
          Resource = [
            "*",
          ]
          Sid = "Statement1"
        }
      ]
    }
  )
}

#-------------------------------------ECS Task IAM Role -------------------------------------#
# Create IAM role for ECS task
resource "aws_iam_role" "role_execution" {
  name = "${var.project.env}-${var.project.name}-execution"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# Create a custom policy 
resource "aws_iam_role_policy" "policy_execution" {
  name = "${var.project.env}-${var.project.name}-execution"
  role = aws_iam_role.role_execution.id

  # Terraform's "jsonencode" function converts a text to valid JSON syntax.

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


# Attach policy to the role
resource "aws_iam_role_policy_attachment" "execution_policy" {
  role       = aws_iam_role.role_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#-------------------------------------ECS Cluster-------------------------------------#
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project.env}-${var.project.name}-ecs-cluster"
  tags = {
    Description = "ECS cluster of ${var.project.env}-${var.project.name}"
  }
}
