#provider "aws" {
#  region = "us-east-1"
#}

resource "aws_ecr_repository" "my_ecr" {
  name                 = "my-private-ecr"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "my_ecr_policy" {
  repository = aws_ecr_repository.my_ecr.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire untagged images after 30 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

# Local-Exec to Build and Push Docker Image
resource "null_resource" "build_and_push_image" {
  provisioner "local-exec" {
    command = <<EOT
aws ecr get-login-password --region ${var.aws_region} | ocker login --username AWS --password-stdin ${local.ecr_url}
docker build -t ${var.ecr_repo_name} ../
docker tag ${var.ecr_repo_name}:latest ${local.ecr_url}:latest
docker push ${local.ecr_url}:latest
EOT
    interpreter = ["bash", "-c"]
  }

depends_on = [aws_ecr_repository.my_ecr]
}

# Variable for region
#variable "region" {
#  default = "us-east-1"
#  description = "AWS region for ECR"
#}



