
locals {
  account_id      = "${data.aws_caller_identity.current.account_id}:"
  target_group_id = split(local.account_id, aws_lb_target_group.python_app_target_group.arn)[1]
  lb_id           = split("${local.account_id}loadbalancer/", aws_lb.python_app_lb.arn)[1]
}


resource "aws_cloudwatch_metric_alarm" "UnHealthyHostCount" {
  alarm_name          = "UnHealthyHostCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "This alarm triggers if the number of unhealthy hosts exceeds the threshold."
  actions_enabled     = true

  dimensions = {
    LoadBalancer = local.lb_id
    TargetGroup  = local.target_group_id
  }
  alarm_actions = [
    aws_sns_topic.email_topic.arn
  ]
  insufficient_data_actions = []
}


resource "aws_cloudwatch_metric_alarm" "HighCpuUtilization" {
  alarm_name          = "HighCpuUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  period              = 30
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "This alarm triggers if the CPU utilization exceeds the threshold."
  actions_enabled     = true

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.python_app.name
  }
  alarm_actions = [
    aws_sns_topic.email_topic.arn
  ]
  insufficient_data_actions = []
}

resource "aws_cloudwatch_dashboard" "app_dashboard" {
  dashboard_name = "AppDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${aws_autoscaling_group.python_app.name}"]
          ]
          title   = "EC2 CPU Utilization"
          view    = "timeSeries"
          stacked = false
          region  = var.region
        }
      },
        {
        type   = "metric",
        x      = 0,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${local.lb_id}"]
          ]
          title   = "Load Balancer Request Count"
          view    = "timeSeries"
          stacked = false
          region  = var.region
        }
        },

        {
          type   = "metric",
          x      = 12,
          y      = 0,
          width  = 12,
          height = 6,
          properties = {
            metrics = [
              ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", "${local.lb_id}"]
            ]
            title   = "ALB HTTP 4XX Error Count"
            view    = "timeSeries"
            stacked = false
            region  = var.region
            stat    = "Sum"
          }
        },
      {
        type   = "metric",
        x      = 12,
        y      = 12,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${local.lb_id}"]
          ]
          title   = "ALB Target Response Time"
          view    = "timeSeries"
          stacked = false
          region  = var.region
        }
      }
    ]
  })
}