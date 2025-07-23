#-------------------------------------EC2 Instance-------------------------------------#
resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ubuntu-ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  subnet_id              = var.subnet_id
  key_name               = var.key_name #aws_key_pair.key_pair.key_name
  root_block_device {
    delete_on_termination = true
    iops                  = var.iops
    volume_size           = var.volume_size
    volume_type           = "gp3"
  }
  depends_on = [
    aws_security_group.ec2-sg
  ]

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${var.instance_name}"
  })

  user_data = var.path_user_data != "" ? file("${var.path_user_data}") : null
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  lifecycle {
    ignore_changes = [
      user_data
    ]
  }
}

# #-------------------------------------Key pair-------------------------------------#
# resource "aws_key_pair" "key_pair" {
#   key_name   = "${var.project.env}-${var.project.name}"
#   public_key = file("${var.path_public_key}")
# }

