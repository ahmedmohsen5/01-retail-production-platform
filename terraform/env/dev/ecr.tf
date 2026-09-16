locals {
  ecr_repositories = toset([
    "retail-ui",
    "retail-catalog",
    "retail-cart",
    "retail-orders",
    "retail-checkout",
  ])
}

resource "aws_ecr_repository" "service" {
  for_each             = local.ecr_repositories
  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
  tags = {
    Name        = "retail-platform-${each.value}-ecr"
    environment = "dev"
    project     = "retail-platform"
  }

}

resource "aws_ecr_lifecycle_policy" "service" {
  for_each   = aws_ecr_repository.service
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}