provider "aws" {
  region = "us-east-1" # Change to your desired region
}

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

# Output the ECR repository URL and region
output "ecr_repository_url" {
  value = aws_ecr_repository.my_ecr.repository_url
}

output "aws_region" {
  value = var.region
}

# Local-Exec to Build and Push Docker Image
resource "null_resource" "build_and_push_image" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.my_ecr.repository_url}
      docker build -f Dockerfile -t ${aws_ecr_repository.my_ecr.name} .
      docker tag ${aws_ecr_repository.my_ecr.name}:latest ${aws_ecr_repository.my_ecr.repository_url}:latest
      docker push ${aws_ecr_repository.my_ecr.repository_url}:latest
    EOT
  }

  depends_on = [aws_ecr_repository.my_ecr]
}

# Variable for region
variable "region" {
  default = "us-east-1"
  description = "AWS region for ECR"
}


