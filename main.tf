data "aws_ami" "python_app_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["python-app-ami"]
  }

  owners = ["self"]
}

data "aws_key_pair" "python_app_key" {
  key_name = "python-app"
}

resource "aws_s3_bucket" "python_code_bucket" {
  bucket = "python-code-bucket"

  tags = {
    Name                 = "PythonCodeBucket"
    created-by-terraform = "true"
  }
}


resource "aws_s3_bucket_public_access_block" "python_code_bucket" {
  bucket                  = aws_s3_bucket.python_code_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "transfer_file" {
  bucket = aws_s3_bucket.python_code_bucket.id
  key    = "server.py"
  source = "python_code/server.py"
  etag   = filemd5("python_code/server.py")
}


resource "aws_launch_template" "python_app" {

  name_prefix            = "python-app-dev-template"
  image_id               = data.aws_ami.python_app_ami.id
  instance_type          = "t2.micro"
  key_name               = data.aws_key_pair.python_app_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_python_app.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.volume_size
      volume_type = "gp2"
    }
  }
  metadata_options {
    http_tokens = "optional"
  }


  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_s3_read_role.name
  }
  user_data = base64encode(<<-EOT
  #!/bin/bash
    mkdir -p /var/www/html
    aws s3 cp s3://${aws_s3_bucket.python_code_bucket.bucket}/server.py /var/www/html/server.py
    python3 /var/www/html/server.py &
EOT
  )
  tags = {
    created-by-terraform = "true"
  }

}

resource "aws_autoscaling_group" "python_app" {
  vpc_zone_identifier = module.vpc.private_subnets
  name                = var.asg_name
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.python_app.id
        version            = "$Latest"
      }

      override {
        instance_type = "t3.micro"
      }

      override {
        instance_type = "t2.micro"
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "lowest-price"
    }
  }

  health_check_type         = "ELB"
  health_check_grace_period = 200
  depends_on                = [aws_s3_object.transfer_file]

  tag {
    key                 = "Name"
    value               = "python-app-asg"
    propagate_at_launch = true
  }
}


resource "aws_security_group" "ec2_python_app" {
  name        = "ec2-python-app-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
    description     = "Allow HTTP access from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name                 = "ec2-python-app-sg"
    created-by-terraform = "true"
  }
}

resource "aws_autoscaling_attachment" "asg_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.python_app.id
  lb_target_group_arn    = aws_lb_target_group.python_app_target_group.arn
}


# # Load Balancer for Python Application
resource "aws_lb" "python_app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Name                 = "app-lb"
    created-by-terraform = "true"
  }
}

# # Application Target Group for Main Backend
resource "aws_lb_target_group" "python_app_target_group" {
  name     = "app-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    interval            = "20"
    matcher             = "200"
    path                = "/healthcheck"
    protocol            = "HTTP"
    timeout             = "10"
  }

  tags = {
    Name                 = "app-target-group"
    created-by-terraform = "true"
  }

}


# # Listener for Python Application Load Balancer
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.python_app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.python_app_target_group.arn
  }
}


resource "aws_security_group" "load_balancer_sg" {
  name        = "load-balancer-sg"
  description = "Allow HTTP traffic to the load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name                 = "load-balancer-sg"
    created-by-terraform = "true"
  }
}