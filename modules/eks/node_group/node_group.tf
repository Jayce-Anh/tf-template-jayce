##################################### NODE GROUP #########################################
#-------------------------- Node Group --------------------------
resource "aws_eks_node_group" "node_groups" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = lookup(each.value, "name", each.key)
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = lookup(each.value, "subnet_ids")
  ami_type        = lookup(each.value, "ami_type", "AL2_x86_64")
  labels          = lookup(each.value, "labels", null)
  release_version = lookup(each.value, "release_version")

#----------- Scaling Config -----------
  scaling_config {
    min_size     = lookup(each.value, "min_size", 1)
    max_size     = lookup(each.value, "max_size", 1)
    desired_size = lookup(each.value, "desired_size", 1)
  }

#----------- Launch Template -----------
  launch_template {
    id      = aws_launch_template.node_groups[each.key].id
    version = aws_launch_template.node_groups[each.key].latest_version
  }

  lifecycle {
    create_before_destroy = true
    # ignore_changes        = [scaling_config[0].desired_size]
  }

#----------- Taints -----------
  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])
    iterator = taint

    content {
      key    = taint.value.key
      value  = lookup(taint.value, "value", "")
      effect = taint.value.effect
    }
  }

#----------- Attach Policies -----------
  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_group_AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.node_group_AmazonEBSCSIDriverPolicy,
  ]

  tags = merge(var.project, lookup(each.value, "tags", {}))
}

#-------------------------- Node Group Role --------------------------
resource "aws_iam_role" "node_group" {
  name = format("%s-eks-node-group", var.name)

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = var.project
}

#----------- Attach Policies to Node Group Role -----------
resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_extra" {
  for_each = { for v in var.extra_iam_policies : v => v }

  policy_arn = each.value
  role       = aws_iam_role.node_group.name
}

#-------------------------- Node Group Security Group --------------------------
resource "aws_security_group" "node_groups" {
  for_each = var.node_groups

  name   = format("%s-%s-eks-node-group-sg", var.name, each.key)
  vpc_id = var.eks_vpc

  dynamic "ingress" {
    for_each = lookup(var.node_group_ingress_rules, "ingress_rules", [
      {
        security_groups = [aws_security_group.eks_cluster.id]
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        description     = "Allow worker nodes to communicate with control plane"
      }
    ])

    content {
      self            = lookup(ingress.value, "self", null)
      security_groups = lookup(ingress.value, "security_groups", null)
      from_port       = lookup(ingress.value, "from_port", null)
      to_port         = lookup(ingress.value, "to_port", null)
      protocol        = lookup(ingress.value, "protocol", null)
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.project
}

#-------------------------- Node Group Launch Template--------------------------
resource "aws_launch_template" "node_groups" {
  for_each = var.node_groups

  name          = format("%s-%s-eks-node-group", var.name, each.key)
  user_data     = can(data.cloudinit_config.node_groups[each.key]) ? data.cloudinit_config.node_groups[each.key].rendered : null
  instance_type = lookup(each.value, "instance_type", "c5.large")
  key_name      = lookup(each.value, "key_name", null)

#Block Device Mappings
  block_device_mappings {
    device_name = lookup(each.value, "device_name", "/dev/xvda")
    ebs {
      volume_size           = lookup(each.value, "disk_size", "20")
      volume_type           = lookup(each.value, "disk_type", "gp3")
      delete_on_termination = lookup(each.value, "delete_on_termination", true)
    }
  }

#Block Device Mappings
  dynamic "block_device_mappings" {
    for_each = can(each.value.block_device_mappings) ? each.value.block_device_mappings : []

    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size           = lookup(block_device_mappings.value, "disk_size", "20")
        volume_type           = lookup(block_device_mappings.value, "disk_type", "gp3")
        snapshot_id           = lookup(block_device_mappings.value, "snapshot_id", null)
        delete_on_termination = lookup(block_device_mappings.value, "delete_on_termination", true)
      }
    }
  }

#Network Interfaces -----------
  network_interfaces {
    security_groups = distinct(concat(
      [
        aws_eks_cluster.eks.vpc_config.0.cluster_security_group_id,
        aws_security_group.node_groups[each.key].id
      ],
      lookup(each.value, "security_group_ids", []),
    ))
    delete_on_termination       = true
    associate_public_ip_address = lookup(each.value, "associate_public_ip_address", false)
  }

#Metadata Options
  metadata_options {
    http_endpoint               = try(each.value.metadata.http_endpoint, "enabled")
    http_tokens                 = try(each.value.metadata.http_tokens, "required")
    http_put_response_hop_limit = try(each.value.metadata.http_put_response_hop_limit, 2)
    instance_metadata_tags      = try(each.value.metadata.instance_metadata_tags, "disabled")
  }

#Tag Specifications
  dynamic "tag_specifications" {
    for_each = ["instance", "volume"]

    content {
      resource_type = tag_specifications.value

      tags = merge(var.project, lookup(each.value, "tags", {}), {
        Name = format("%s-eks-%s-node-group", var.name, each.key)
      })
    }
  }

  tags = var.project
}

#-------------------------- Node Group Cloud-Init Config--------------------------
data "cloudinit_config" "node_groups" {
  for_each = {
    for k, v in var.node_groups :
    k => v.block_device_mappings
    if can(v.block_device_mappings)
  }

  base64_encode = true
  gzip          = false

  dynamic "part" {
    for_each = {
      for k, v in each.value :
      k => v
      if !can(v.snapshot_id)
    }

    content {
      content_type = "text/x-shellscript"
      content      = <<EOF
      mkfs -t ext4 ${part.value.device_name}
      EOF
    }
  }

  dynamic "part" {
    for_each = each.value

    content {
      content_type = "text/x-shellscript"
      content      = <<EOF
      mkdir -p ${part.value.mount_path}
      mount ${part.value.device_name} ${part.value.mount_path}
      echo "${part.value.device_name} ${part.value.mount_path} ext4  defaults,nofail,discard,comment=cloudconfig 0 0" >> /etc/fstab
      EOF
    }
  }
}

