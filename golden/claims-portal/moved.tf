# State migration from the legacy single-file stack (legacy/main.tf).
#
# These blocks map every legacy resource address to its new home inside the
# approved modules, so an existing workspace keeps its resources instead of
# destroying and recreating them. Where the approved modules use a different
# naming convention (for example ALB, target group, and security group
# names), the plan will still show an in-place update or a replacement for
# that attribute. Review the plan before applying.

# network -> app.terraform.io/<your-org>/vpc/aws

moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.ecs
}

moved {
  from = aws_internet_gateway.gw
  to   = module.network.aws_internet_gateway.igw
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public_custom_route_table
}

moved {
  from = aws_subnet.public_a
  to   = module.network.aws_subnet.public[0]
}

moved {
  from = aws_subnet.public_b
  to   = module.network.aws_subnet.public[1]
}

moved {
  from = aws_route_table_association.a
  to   = module.network.aws_route_table_association.public_crt_public_subnet[0]
}

moved {
  from = aws_route_table_association.b
  to   = module.network.aws_route_table_association.public_crt_public_subnet[1]
}

# compute -> app.terraform.io/<your-org>/ecs-cluster/aws

moved {
  from = aws_ecs_cluster.claims
  to   = module.ecs_cluster.aws_ecs_cluster.ecs_cluster
}

moved {
  from = aws_security_group.alb
  to   = module.ecs_cluster.aws_security_group.ecs_alb_sg
}

moved {
  from = aws_security_group.ecs
  to   = module.ecs_cluster.aws_security_group.ecs_sg
}

moved {
  from = aws_instance.ecs_node_1
  to   = module.ecs_cluster.aws_instance.ecs_instance[0]
}

moved {
  from = aws_instance.ecs_node_2
  to   = module.ecs_cluster.aws_instance.ecs_instance[1]
}

moved {
  from = aws_lb.claims
  to   = module.ecs_cluster.aws_lb.ecs_alb
}

moved {
  from = aws_lb_target_group.claims
  to   = module.ecs_cluster.aws_lb_target_group.ecs_alb_tg
}

moved {
  from = aws_lb_listener.http
  to   = module.ecs_cluster.aws_lb_listener.front_end
}

moved {
  from = aws_lb_target_group_attachment.node_1
  to   = module.ecs_cluster.aws_lb_target_group_attachment.ecs_alb_tg_attachment[0]
}

moved {
  from = aws_lb_target_group_attachment.node_2
  to   = module.ecs_cluster.aws_lb_target_group_attachment.ecs_alb_tg_attachment[1]
}

# workload -> app.terraform.io/<your-org>/nginx-ecs/aws

moved {
  from = aws_ecs_task_definition.nginx
  to   = module.nginx.aws_ecs_task_definition.nginx_task
}

moved {
  from = aws_ecs_service.nginx
  to   = module.nginx.aws_ecs_service.nginx_service
}

# storage -> ./modules/secure-bucket

moved {
  from = aws_s3_bucket.claims_documents
  to   = module.documents_bucket.aws_s3_bucket.this
}
