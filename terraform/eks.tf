resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker_role.name
}

# Get ECR Authorization Token
data "aws_ecr_authorization_token" "token" {}

# Configure Docker Provider (optional, if using Terraform for Docker)
provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.token.proxy_endpoint
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

# Kubernetes Secret for ECR authentication
resource "kubernetes_secret" "ecr_credentials" {
  metadata {
    name      = "ecr-credentials"
    namespace = "default"
  }

  data = {
    ".dockerconfigjson" = base64encode(data.aws_ecr_authorization_token.token.proxy_endpoint)
  }

  type = "kubernetes.io/dockerconfigjson"
}

# Kubernetes Deployment (using ECR image)
resource "kubernetes_deployment" "my_app_deployment" {
  metadata {
    name = "my-app-deployment"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }

      spec {
        container {
          name  = "my-app-container"
          image = "${data.aws_ecr_authorization_token.token.proxy_endpoint}/my-private-ecr:latest"

          ports {
            container_port = 3000
          }
        }

        image_pull_secrets {
          name = kubernetes_secret.ecr_credentials.metadata[0].name
        }
      }
    }
  }
}
