# ==============================
# EC2 CPU Alarm - web-1a
# ==============================

resource "aws_cloudwatch_metric_alarm" "web_1a_cpu_high" {
  alarm_name          = "${var.project_name}-web-1a-cpu-high"
  alarm_description   = "CPU utilization is 80% or higher on web-1a"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.web_1a.id
  }
}

# ==============================
# EC2 CPU Alarm - web-1c
# ==============================

resource "aws_cloudwatch_metric_alarm" "web_1c_cpu_high" {
  alarm_name          = "${var.project_name}-web-1c-cpu-high"
  alarm_description   = "CPU utilization is 80% or higher on web-1c"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.web_1c.id
  }
}

# ==============================
# ALB Unhealthy Host Alarm
# ==============================

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  alarm_description   = "ALB target group has unhealthy hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }
}
