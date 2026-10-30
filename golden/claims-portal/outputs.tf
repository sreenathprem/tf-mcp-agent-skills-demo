output "alb_url" {
  description = "Public URL of the claims portal load balancer."
  value       = "http://${module.ecs_cluster.ecs_alb_url}"
}

output "documents_bucket_arn" {
  description = "ARN of the claim documents bucket."
  value       = module.documents_bucket.bucket_arn
}

output "documents_bucket_name" {
  description = "Name of the claim documents bucket."
  value       = module.documents_bucket.bucket_name
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster."
  value       = module.ecs_cluster.ecs_cluster_id
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}
