# ---------------------------------------------------------------------------
# ECR: private container registry for the application images.
# Nodes pull from it through the node role (AmazonEC2ContainerRegistryPullOnly in nodes.tf),
# so no imagePullSecret is needed for images stored here.
# ---------------------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  for_each = toset(var.ecr_repository_names)

  name                 = "${var.cluster_name}/${each.value}"
  image_tag_mutability = "IMMUTABLE" # a tag like v1.2.0 can never be overwritten

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Keep storage cost down: expire untagged images and keep only the latest N tagged ones.
resource "aws_ecr_lifecycle_policy" "app" {
  for_each   = aws_ecr_repository.app
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.ecr_keep_last_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_keep_last_images
        }
        action = { type = "expire" }
      }
    ]
  })
}
