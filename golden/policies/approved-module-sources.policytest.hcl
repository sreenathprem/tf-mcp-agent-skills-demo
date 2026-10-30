policytest {
  targets = ["approved-module-sources.policy.hcl"]
}

module "app.terraform.io/<your-org>/vpc/aws" "approved_private_module" {
  meta = {
    source  = "app.terraform.io/<your-org>/vpc/aws"
    address = "module.network"
    version = "0.0.2"
  }
}

module "./modules/secure-bucket" "local_module" {
  meta = {
    source  = "./modules/secure-bucket"
    address = "module.documents_bucket"
  }
}

module "registry.terraform.io/terraform-aws-modules/vpc/aws" "public_registry_module" {
  expect_failure = true
  meta = {
    source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
    address = "module.vpc"
    version = "6.0.0"
  }
}

module "github.com/someone/terraform-aws-ecs" "git_module" {
  expect_failure = true
  meta = {
    source  = "github.com/someone/terraform-aws-ecs"
    address = "module.ecs"
  }
}
