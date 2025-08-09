# File: diagnostics.tf (new, at root)

# After your loki module exists
```hcl
data "aws_ecs_container_definition" "loki" {
  task_definition = module.loki.task_definition_arn
  container_name  = "loki"
}

output "loki_image_effective" {
  value = data.aws_ecs_container_definition.loki.image
}

output "loki_container_port_effective" {
  value = try(data.aws_ecs_container_definition.loki.port_mappings[0].container_port, null)
}

output "loki_log_group_effective" {
  value = try(data.aws_ecs_container_definition.loki.log_configuration[0].options["awslogs-group"], null)
}

output "loki_mount_points_effective" {
  value = data.aws_ecs_container_definition.loki.mount_points
}
```
Do not feed these values back into ALB/TG creation—keep them for visibility only.

No module edits required; no risk of cycles.

# efs_container_path = "/mnt/config"

command = ["-config.file=/mnt/config/local-config.yaml"]
```hcl
 module "loki" {
   source              = "./modules/ecs-service"
   name                = "loki"
   image               = "public.ecr.aws/bitnami/grafana-loki:3.5.0"
   container_port      = 3100
   cpu                 = 512
   memory              = 1024
   env_vars            = {}

   execution_role_arn  = aws_iam_role.ecs_execution.arn
   task_role_arn       = aws_iam_role.loki_task.arn

   cluster_id          = module.cluster.cluster_id
   ecs_sg_id           = module.cluster.ecs_sg_id
   vpc_id              = var.vpc_id
   subnet_ids          = var.subnet_ids

   # EFS
   efs_file_system_id  = module.efs.efs_file_system_id
   efs_access_point_id = module.efs.efs_access_point_id
   efs_sg_id           = module.efs.efs_sg_id
   depends_on_efs      = module.efs.efs_mount_target_ids

  # Mount EFS at /mnt/config and point Loki at the file there
  efs_container_path  = "/mnt/config"
  command             = ["-config.file=/mnt/config/local-config.yaml"]

   load_balancers = [
     {
       container_name   = "loki"
       container_port   = 3100
       target_group_arn = aws_lb_target_group.loki.arn
     }
   ]
 }
```
Notes:

File on EFS at /shared-config/local-config.yaml

Flip your ALB to internet-facing:
resource "aws_lb" "app" {
internal = true X
internal = false
}

- Ensure your TG is Fargate-friendly:
```diff
resource "aws_lb_target_group" "loki" {
   port     = 3100
   protocol = "HTTP"
   vpc_id   = var.vpc_id
+    target_type = "ip"
   # health_check ...
}
