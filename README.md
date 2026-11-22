# Enterprise EKS on AWS (Terraform + GitHub Actions)

Region `ap-south-2`, dev environment. Plain resources, no modules.

## What is in this repo

| Path | Purpose | Applied by |
|---|---|---|
| `bootstrap/` | S3 state bucket, GitHub OIDC provider, IAM role for CI | **You, once, from your Mac** |
| `*.tf` (repo root) | VPC, EKS, node group, add-ons, Pod Identity, WAF, ECR, monitoring | **GitHub Actions** |
| `.github/workflows/terraform.yml` | The pipeline | GitHub |

## Why bootstrap comes first

GitHub Actions cannot log in to AWS until the OIDC provider and IAM role exist, and Terraform cannot
store state in a bucket that does not exist yet. Both are created by `bootstrap/`, so that stack is
the only manual step. Everything after it runs in CI.

## Start to end

### Step 1. Prerequisites (Mac, once)
- Terraform >= 1.10, AWS CLI v2, an AWS login with admin rights in the target account.
- `aws login` (or your SSO login), then check with `aws sts get-caller-identity`.

### Step 2. Bootstrap (Mac, once)
```
cd bootstrap
terraform init
terraform apply -var github_repo=Anudeepkumar7/terraform-eks-end-ro-end
terraform output            # note state_bucket and github_actions_role_arn
```
If it fails with "EntityAlreadyExists" for the OIDC provider, import the existing one:
```
terraform import aws_iam_openid_connect_provider.github \
  arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com
```
Keep `bootstrap/terraform.tfstate` safe. It is git-ignored and only tracks the bucket and role.

### Step 3. GitHub repo settings (browser, once)
1. Settings > Secrets and variables > Actions > **Variables** > New repository variable:

| Name | Value | Required |
|---|---|---|
| `AWS_ROLE_ARN` | `github_actions_role_arn` from step 2 | yes |
| `TF_STATE_BUCKET` | `state_bucket` from step 2 | yes |
| `API_CIDRS` | `["<your-ip>/32"]` (see note below) | yes |
| `CLUSTER_ADMIN_ARNS` | `["arn:aws:iam::<id>:role/<name>"]` for your own kubectl access | no |
| `ALARM_EMAIL` | your email | no |
| `RUNNER_LABEL` | label of a self-hosted runner inside the VPC | no |

2. Settings > Environments > New environment `dev` > tick **Required reviewers** > add yourself.

> `API_CIDRS` note: GitHub-hosted runners use GitHub's IPs, not yours. With a public API endpoint the
> Helm installs only work if the runner can reach it. For a first run use `["0.0.0.0/0"]`, then tighten
> it or move to a self-hosted runner inside the VPC.

### Step 4. Get the code onto `main`
The pipeline only runs for pull requests and pushes to `main`.
1. Open a pull request from `terraform-eks-end` into `main` (create `main` first if the repo has none).
2. The **plan** job runs. Read the plan in the run's Summary tab.
3. Merge the PR.

### Step 5. Apply (GitHub Actions)
1. After the merge, the **plan** job runs again and saves the plan.
2. The **apply** job waits for approval of the `dev` environment. Open the run, read the plan, then
   **Review deployments > Approve**.
3. Creation takes about 20 to 30 minutes (EKS cluster, node group, add-ons, Helm releases).

### Step 6. Connect to the cluster
```
aws eks update-kubeconfig --name dev-eks --region ap-south-2
kubectl get nodes
```
Your identity must be in `CLUSTER_ADMIN_ARNS`, and your IP in `API_CIDRS`, or kubectl is denied.

### Step 7. Deploy your app
1. Push an image to ECR (URL is the `ecr_repository_urls` output):
   ```
   aws ecr get-login-password --region ap-south-2 | docker login --username AWS --password-stdin <registry>
   docker build -t <repo-url>:v1.0.0 . && docker push <repo-url>:v1.0.0
   ```
2. Create a Deployment, a Service and an Ingress with `ingressClassName: alb` and the annotation
   `alb.ingress.kubernetes.io/wafv2-acl-arn: <waf_acl_arn output>`.
3. The Load Balancer Controller creates the ALB.

### Later changes
Edit code on a branch, open a PR, review the plan, merge, approve. Do not run `apply` from your Mac.

## Not covered yet
- Destroy workflow (deliberately absent).
- Moving the bootstrap state into the S3 bucket.
- A self-hosted runner for a fully private API endpoint.
