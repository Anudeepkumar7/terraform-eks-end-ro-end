variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "dev-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.35"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 3
}

variable "single_nat_gateway" {
  description = "true = one shared NAT gateway (cheap, for dev). false = one NAT per AZ (production)."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint. Restrict this to your office/VPN IP, e.g. [\"203.0.113.10/32\"]."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "node_disk_size" {
  description = "Node root volume size in GiB"
  type        = number
  default     = 50
}

variable "waf_rate_limit" {
  description = "Max requests per 5 minutes from a single IP before WAF blocks it"
  type        = number
  default     = 2000
}

variable "log_retention_days" {
  description = "Retention in days for the Container Insights and WAF log groups"
  type        = number
  default     = 30
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications. Empty = topic is created with no subscriber. The recipient must confirm the subscription."
  type        = string
  default     = ""
}

variable "waf_blocked_alarm_threshold" {
  description = "Alarm when WAF blocks more than this many requests in 5 minutes"
  type        = number
  default     = 500
}

variable "app_namespace" {
  description = "Kubernetes namespace of your application"
  type        = string
  default     = "app"
}

variable "app_service_account" {
  description = "Kubernetes ServiceAccount used by your application pods"
  type        = string
  default     = "app"
}

variable "app_policy_arns" {
  description = "IAM policy ARNs to attach to the application's Pod Identity role (e.g. S3 read). Empty = role with no permissions."
  type        = map(string)
  default     = {}
}

variable "cluster_admin_arns" {
  description = "Extra IAM role/user ARNs to grant cluster admin (SSO roles, teammates). The identity running Terraform is added automatically."
  type        = list(string)
  default     = []
}

variable "ecr_repository_names" {
  description = "ECR repositories to create for your app images. Each becomes <cluster_name>/<name>."
  type        = list(string)
  default     = ["app"]
}

variable "ecr_keep_last_images" {
  description = "Number of images to keep per ECR repository; older ones expire"
  type        = number
  default     = 30
}

variable "ecr_snapshot_expire_days" {
  description = "Days after which PR snapshot images (tag prefix snapshot-) expire from ECR"
  type        = number
  default     = 7
}


variable "ecr_push_github_repo" {
  description = "GitHub repo (owner/name) whose Actions pipeline may push images to ECR via OIDC (the repo that builds the images)"
  type        = string
  default     = "Anudeepkumar7/ultimate-devops-project-demo"
}

variable "ecr_push_allow_pull_requests" {
  description = "Also let pull request runs of that repo assume the push role (for snapshot-* tags). false = main branch only."
  type        = bool
  default     = true
}
