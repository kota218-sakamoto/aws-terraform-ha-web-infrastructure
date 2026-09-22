# ==============================
# Application Load Balancer
# ==============================

resource "aws_lb" "web" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1c.id
  ]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ==============================
# Target Group
# ==============================

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# ==============================
# ALB Listener
# ==============================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
