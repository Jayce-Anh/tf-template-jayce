################################# S3 BUCKET #################################
#Create S3 Bucket
resource "aws_s3_bucket" "s3" {
  bucket = "${var.project.env}-${var.project.name}-${var.service_name}"

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${var.service_name}-s3cf"
  })
}

# resource "aws_s3_bucket_acl" "s3" {
#   bucket = aws_s3_bucket.s3.id
#   acl    = var.bucket_acl
# }

resource "aws_s3_bucket_versioning" "s3" {
  bucket = aws_s3_bucket.s3.id

  versioning_configuration {
    status     = lookup(var.versioning, "status", lookup(var.versioning, "enabled", "Enabled"))
    mfa_delete = lookup(var.versioning, "mfa_delete", null)
  }
}

#S3 Ownership Controls
resource "aws_s3_bucket_ownership_controls" "s3" {
  count = var.ownership_config != null ? 1 : 0

  bucket = aws_s3_bucket.s3.id

  rule {
    object_ownership = lookup(var.ownership_config, "object_ownership", "BucketOwnerPreferred")
  }
}


