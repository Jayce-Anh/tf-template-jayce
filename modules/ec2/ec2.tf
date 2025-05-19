#-------------------------------------Get AMI ID-------------------------------------#
data "aws_ami" "ubuntu-ami" {
  most_recent = true
  owners      = ["099720109477"]
  # name_regex = "ubuntu"
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#-------------------------------------Security Group-------------------------------------#
resource "aws_security_group" "ec2-sg" {

  vpc_id      = var.network.vpc_id
  description = "${var.project.env}-${var.project.name}-ec2-sg"
  name        = "${var.project.env}-${var.project.name}-ec2"
}

#Security Group Rule
resource "aws_security_group_rule" "rule-ec2-ingress-1" {
  description = "Allow port SSH"
  security_group_id = aws_security_group.ec2-sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.source_ingress_ec2_sg_cidr  
}

resource "aws_security_group_rule" "rule-ec2-ingress-2" {
  description = "Allow port 80 to ALB"
  security_group_id = aws_security_group.ec2-sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = var.alb_sg_id
}

resource "aws_security_group_rule" "rule-ec2-ingress-3" {
  description = "Allow port 443 to ALB"
  security_group_id = aws_security_group.ec2-sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = var.alb_sg_id
}

resource "aws_security_group_rule" "rule-ec2-egress" {
  security_group_id = aws_security_group.ec2-sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

#-------------------------------------EIP-------------------------------------# 
resource "aws_eip" "eip" {
  count = var.enabled_eip ? 1 : 0

  domain = "vpc"
  tags = {
    Name = "${var.project.env}-${var.project.name}-${var.instance_name}"

    env     = "${var.project.env}"
    project = "${var.project.name}"

  }
}

#EIP Association
resource "aws_eip_association" "eip_assoc" {
  count = var.enabled_eip ? 1 : 0

  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.eip[0].id
}

#-------------------------------------EC2 Instance-------------------------------------#
resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ubuntu-ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  root_block_device {
    delete_on_termination = true
    iops                  = var.iops
    volume_size           = var.volume_size
    volume_type           = "gp3"
  }
  depends_on = [
    aws_security_group.ec2-sg
  ]

  tags = {
    Name    = "${var.project.env}-${var.project.name}-${var.instance_name}"
    env     = "${var.project.env}"
    project = "${var.project.name}"
  }

  user_data = "${path.module}/modules/ec2/user_data/user_data.sh"  #var.path_user_data != "" ? file("${var.path_user_data}") : null
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  lifecycle {
    ignore_changes = [
      user_data
    ]
  }
}

#-------------------------------------Key pair-------------------------------------#
# resource "aws_key_pair" "key_pair" {
#   key_name   = "${var.project.env}-${var.project.name}"
#   public_key = file("${var.path_public_key}")
# }

#-------------------------------------IAM roles-------------------------------------#
resource "aws_iam_role" "ec2_role" {
  name = "${var.project.env}-${var.project.name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
  })
}

#Allow EC2 access to SSM
resource "aws_iam_role_policy_attachment" "ssm_role_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#Allow EC2 access to ECR
resource "aws_iam_role_policy_attachment" "ecr_role_attachment" {
  role       = aws_iam_role.ec2_role.name 
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

#Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project.env}-${var.project.name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
