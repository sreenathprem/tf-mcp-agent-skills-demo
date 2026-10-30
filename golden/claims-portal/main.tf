# Latest ECS-optimised Amazon Linux 2023 AMI, published by AWS. Replaces the
# hardcoded AMI ID from the legacy stack.
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# Approved modules from the <your-org> private registry

module "network" {
  source  = "app.terraform.io/<your-org>/vpc/aws"
  version = "0.0.2"

  env                       = var.environment
  vpc_cidr_block            = var.vpc_cidr
  public_subnet_cidr_blocks = var.public_subnet_cidrs
}

module "ecs_cluster" {
  source  = "app.terraform.io/<your-org>/ecs-cluster/aws"
  version = "0.0.6"

  name                  = local.name_prefix
  node_size             = var.node_count
  ec2_ami               = data.aws_ssm_parameter.ecs_ami.insecure_value
  ec2_instance_type     = var.instance_type
  vpc_id                = module.network.vpc_id
  vpc_public_subnet_ids = module.network.public_subnet_ids
}

module "nginx" {
  source  = "app.terraform.io/<your-org>/nginx-ecs/aws"
  version = "1.23.0"

  ecs_cluster_id = module.ecs_cluster.ecs_cluster_id
  replicas       = var.nginx_replicas
}

# No approved S3 module exists in the private registry, so claim documents use
# a local module built on current AWS provider resources.
module "documents_bucket" {
  source = "./modules/secure-bucket"

  bucket_name = "${local.name_prefix}-claims-documents"
  kms_key_arn = var.documents_kms_key_arn
}
