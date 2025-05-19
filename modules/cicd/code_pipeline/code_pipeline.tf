#-------------------------- S3 Bucket for CodePipeline artifact -------------------------- 
resource "aws_s3_bucket" "bucket_artifact" {
  bucket = "${var.project.env}-${var.project.name}-codepipeline-bucket-sotatek"
}

#-------------------------- CodePipeline --------------------------
resource "aws_codepipeline" "codepipeline" {
  name     = "${var.project.env}-${var.project.name}-${var.pipeline_name}"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.bucket_artifact.bucket
    type     = "S3"
  }

#Source Stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["Source_Artifacts"]

      configuration = {
        Owner      = var.git_org
        Repo       = var.git_repo
        Branch     = var.git_branch
        OAuthToken = var.git_token
      }
    }
  }

#Build Stage
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_Artifacts"]
      output_artifacts = ["Build_Artifacts"]
      version          = "1"

      configuration = {
        ProjectName = var.project_name # Codebuild project name
      }
    }
  }

# #Deploy Stage 
#   stage {
#     name = "Deploy"

#     action {
#       name             = "Deploy"
#       category         = "Deploy"
#       owner            = "AWS"
#       provider         = "CodeDeploy"
#       input_artifacts  = ["Build_Artifacts"]
#       output_artifacts = ["Deploy_Artifacts"]
#       version          = "1"

#       configuration = {
#         ApplicationName = var.application_name # CodeDeploy application name
#         DeploymentGroupName = var.deployment_group_name # CodeDeploy deployment group name
#       }
#     }
#   }

}

# A shared secret between GitHub and AWS that allows AWS
# CodePipeline to authenticate the request came from GitHub.
# Would probably be better to pull this from the environment
# or something like SSM Parameter Store.

#-------------------------- Integrate CodePipeline with GitHub --------------------------
#Connect to GitHub with OAuth Token
provider "github" {
  token = var.git_token
  owner = var.git_org
}

#Generate a random secret token for the CodePipeline webhook
resource "random_string" "secret_token" {
  length  = 99
  special = false
}

#CodePipeline webhook
resource "aws_codepipeline_webhook" "bar" {
  name            = "${var.project.name}-${var.project.env}-${var.pipeline_name}-webhook"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.codepipeline.name

  authentication_configuration {
    secret_token = random_string.secret_token.result
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}


## Wire the CodePipeline webhook into a GitHub repository.
#resource "github_repository_webhook" "bar" {
#  repository = var.gitRepo
#
#  configuration {
#    url          = aws_codepipeline_webhook.bar.url
#    content_type = "json"
#    insecure_ssl = false
#    secret       = random_string.secret_token.result
#  }
#
#  events = ["push"]
#}

########################################################################################

#-------------------------- CodeDeploy Role --------------------------
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.project.env}_code_deploy_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#CodeDeploy Policy
resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_role.name
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS" #Allow codedeploy have permission to call ECS
  role       = aws_iam_role.codedeploy_role.name
}

#-------------------------- CodePipeline Role --------------------------
resource "aws_iam_role" "pipeline_role" {
  name = "${var.project.name}-${var.project.env}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#CodePipeline Policy
resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.pipeline_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:PassRole"
        ],
        Resource  = "*",
        Effect    = "Allow",
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "cloudformation.amazonaws.com",
              "elasticbeanstalk.amazonaws.com",
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        Action = [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "elasticbeanstalk:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "s3:*",
          "sns:*",
          "cloudformation:*",
          "rds:*",
          "sqs:*",
          "ecs:*"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "opsworks:CreateDeployment",
          "opsworks:DescribeApps",
          "opsworks:DescribeCommands",
          "opsworks:DescribeDeployments",
          "opsworks:DescribeInstances",
          "opsworks:DescribeStacks",
          "opsworks:UpdateApp",
          "opsworks:UpdateStack"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Effect = "Allow",
        Action = [
          "devicefarm:ListProjects",
          "devicefarm:ListDevicePools",
          "devicefarm:GetRun",
          "devicefarm:GetUpload",
          "devicefarm:CreateUpload",
          "devicefarm:ScheduleRun"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "servicecatalog:ListProvisioningArtifacts",
          "servicecatalog:CreateProvisioningArtifact",
          "servicecatalog:DescribeProvisioningArtifact",
          "servicecatalog:DeleteProvisioningArtifact",
          "servicecatalog:UpdateProduct"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudformation:ValidateTemplate"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:DescribeImages"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "states:DescribeExecution",
          "states:DescribeStateMachine",
          "states:StartExecution"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "appconfig:StartDeployment",
          "appconfig:StopDeployment",
          "appconfig:GetDeployment"
        ],
        Resource = "*"
      }
    ]
  })
}

#-------------------------- CodeBuild Role --------------------------
resource "aws_iam_role" "codebuild_role" {
  name               = "${var.project.name}-${var.project.env}-codebuild-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

}

#CodeBuild Policy
resource "aws_iam_role_policy" "s3_policy_cicd" {
  role = aws_iam_role.codebuild_role.name

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
            "logs:*"
          ]
        },
        {
          Effect   = "Allow",
          Resource = [
            "*"
          ],
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:CompleteLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:InitiateLayerUpload",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetAuthorizationToken",
            "ecr:PutImage"
          ]
        },
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
          Effect   = "Allow",
          Resource = [
            "*"
          ],
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject"
          ]
        },
        {
          Action = [
            "cloudfront:CreateInvalidation",
            "cloudfront:GetDistribution",
            "cloudfront:GetStreamingDistribution",
            "cloudfront:GetDistributionConfig",
            "cloudfront:GetInvalidation",
            "cloudfront:ListInvalidations",
            "cloudfront:ListStreamingDistributions",
            "cloudfront:ListDistributions"
          ],
          Effect   = "Allow",
          Resource = [
            "*"
          ],
        },
        {
          Effect   = "Allow",
          Resource = [
            aws_s3_bucket.bucket_artifact.arn,
            "${aws_s3_bucket.bucket_artifact.arn}/*"
          ],
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:PutObjectTagging",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
          ]
        }
      ]
    }
  )
}

