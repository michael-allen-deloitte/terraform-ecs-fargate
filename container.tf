# container | container.tf

# container template
data "template_file" "app" {
  template = file("./container.json")

  vars = {
    app_name       = var.app_name
    app_image      = var.app_image
    app_port       = var.app_port
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
  }
}

# ECS task definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-task"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.app.rendered
}

# ECS service
resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.aws-ecs.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.aws-ecs-tasks.id]
    subnets          = aws_subnet.aws-subnet.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = var.app_name
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.front_end]

   tags = {
    Name = "${var.app_name}-ecs"
  }
}

 