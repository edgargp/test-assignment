output "alb_dns_name" {
    value = aws_lb.python_app_lb.dns_name
}