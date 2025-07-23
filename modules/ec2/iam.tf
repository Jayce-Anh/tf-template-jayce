#-------------------------------------IAM roles-------------------------------------#
resource "aws_iam_role" "ec2_role" {
  name = "${var.project.env}-${var.project.name}-${var.instance_name}-role"
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
  name = "${var.project.env}-${var.project.name}-${var.instance_name}-profile"
  role = aws_iam_role.ec2_role.name
}
