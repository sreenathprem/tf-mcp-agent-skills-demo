# Claims Portal modernisation

We are moving the legacy claims portal stack (`legacy/main.tf`) onto the
platform team's approved Terraform modules and onto HCP Terraform.

## Environment

- HCP Terraform organization: `<your-org>` (app.terraform.io), project `aws`
- Cloud: AWS, region `eu-central-1`
- Terraform CLI: latest (1.16.x). Terraform Policy CLI: `tfpolicy`

## Rules

- Before writing any Terraform, look up versions and modules through the
  Terraform MCP server. Search the **private registry** (`<your-org>`)
  first. Use the public registry only for gaps, and say which gap.
- Pin every module and provider version you reference to what the registry
  returns. Do not guess versions or arguments from memory.
- Follow the HashiCorp style guide for all HCL. Run `terraform fmt -recursive`
  and `terraform validate` after every change.
- New code goes in `claims-portal/`. Policies go in `policies/`.
- **Never apply.** Do not run `terraform apply`, and do not start or approve an
  apply through MCP. Plans and speculative plans only.
- Never print or write secrets. AWS credentials come from an HCP Terraform
  variable set.
