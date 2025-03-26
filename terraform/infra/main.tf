#database

# resource "aws_db_subnet_group" "db_subnet_group" {
#   name       = "db_subnet_group"
#   subnet_ids = [data.aws_subnet.orbwatch_subnet1.id, data.aws_subnet.orbwatch_subnet2.id]
# }

# resource "aws_db_instance" "orbwatch_db" {
#   identifier = "orbwatch-db"
#   provider = aws
#   allocated_storage = 20
#   db_name = "orbwatchdb"
#   engine = "mysql"
#   engine_version = "8.0.40"
#   instance_class = "db.t3.micro"
#   username = var.db_username
#   password = var.db_password
#   parameter_group_name = "default.mysql8.0"
#   publicly_accessible = true
#   skip_final_snapshot = true
#   vpc_security_group_ids = [data.aws_security_group.db_sg.id]
#   db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

#   tags = {
#     Name = "orbwatch-db"
#   }
# }

# launch template
resource "aws_launch_template" "orbwatch_launch_template" {
  name = "orbwatch-launch-template"
  image_id = "ami-01eb4eefd88522422"
  instance_type = "t3.micro"
  key_name = "orb-kp"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [data.aws_security_group.orbwatch_sg.id]
  }

  iam_instance_profile {
    name = "ecsInstanceRole"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  user_data = base64encode(data.template_file.user_data.rendered)
  depends_on = [aws_ecs_cluster.orbwatch_cluster]
  tags = {
    Name = "orbwatch-launch-template"
  }
}

#target group
resource "aws_lb_target_group" "orbwatch_target_group" {
  name = "orbwatch-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.orbwatch_vpc.id
  target_type = "ip"

  health_check {
    path = "/"
  }
}
#alb

resource "aws_lb" "orbwatch_alb" {
  name = "orbwatch-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [data.aws_security_group.orbwatch_sg.id]
  subnets = [
    data.aws_subnet.orbwatch_subnet1.id,
    data.aws_subnet.orbwatch_subnet2.id
  ]
}
#listener http

resource "aws_lb_listener" "orbwatch_listener" {
  load_balancer_arn = aws_lb.orbwatch_alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.orbwatch_target_group.arn
  }
}
#listener https
# resource "aws_lb_listener" "orbwatch_listener_https" {
#   load_balancer_arn = aws_lb.orbwatch_alb.arn
#   port = 443
#   protocol = "HTTPS"
#   certificate_arn = var.certificate_arn

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.orbwatch_target_group.arn
#   }
# }

#asg
resource "aws_autoscaling_group" "orbwatch_asg" {
  name = "orbwatch-asg"
  min_size = 1
  max_size = 1
  desired_capacity = 1
  vpc_zone_identifier = [
    data.aws_subnet.orbwatch_subnet1.id,
    data.aws_subnet.orbwatch_subnet2.id
  ]

  launch_template {
    id = aws_launch_template.orbwatch_launch_template.id
    version = "$Latest"
  }
}

#ecs cluster

resource "aws_ecs_cluster" "orbwatch_cluster" {
  name = "orbwatch-cluster"
}
#ecs service

