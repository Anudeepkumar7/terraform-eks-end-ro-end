output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "configure_kubectl" {
  description = "Run this to connect kubectl to the cluster"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${var.region}"
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "waf_acl_arn" {
  description = "Add to your Ingress: alb.ingress.kubernetes.io/wafv2-acl-arn"
  value       = aws_wafv2_web_acl.alb.arn
}

output "app_pod_identity_role_arn" {
  description = "IAM role your app pods assume (ServiceAccount app/app)"
  value       = aws_iam_role.app.arn
}

output "ecr_repository_urls" {
  description = "Push your images here, e.g. docker push <url>:<tag>"
  value       = { for k, r in aws_ecr_repository.app : k => r.repository_url }
}

output "ecr_push_role_arn" {
  description = "Use as AWS_ROLE_ARN in the image-building repo's docker-ecr workflow"
  value       = aws_iam_role.ecr_push.arn
}
