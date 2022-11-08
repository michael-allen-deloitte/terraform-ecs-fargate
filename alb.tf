# Define Application Load Balancer - alb.tf

resource "aws_alb" "main" {
  name            = "${var.app_name}-load-balancer"
  subnets         = aws_subnet.aws-subnet.*.id
  security_groups = [aws_security_group.aws-lb.id]
  tags = {
    Name = "${var.app_name}-alb"
  }
}

resource "aws_alb_target_group" "app" {
  name        = "${var.app_name}-target-group"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.aws-vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTPS"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
  tags = {
    Name = "${var.app_name}-alb-target-group"
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = var.app_port
  protocol          = "HTTPS"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
}

# output lb public ip
output "dns_lb" {
  description = "DNS load balancer"
  value       = aws_alb.main.dns_name 
}
