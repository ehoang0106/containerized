#database

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [data.aws_subnet.orbwatch_subnet1.id, data.aws_subnet.orbwatch_subnet2.id]
}

resource "aws_db_instance" "orbwatch_db" {
  identifier = "orbwatch-db"
  provider = aws
  allocated_storage = 20
  db_name = "mydb"
  engine = "mysql"
  engine_version = "8.0.40"
  instance_class = "db.t3.micro"
  username = var.db_username
  password = var.db_password
  parameter_group_name = "default.mysql8.0"
  publicly_accessible = true
  skip_final_snapshot = true
  vpc_security_group_ids = [data.aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  tags = {
    Name = "orbwatch-db"
  }
}

# launch template
resource "aws_launch_template" "orbwatch_launch_template" {
  name = "orbwatch-launch-template"
  image_id = "ami-01eb4eefd88522422"
  instance_type = "t3.micro"
  key_name = "orb-kp"

  # network_interfaces {
  #   associate_public_ip_address = true
  #   security_groups = [data.aws_security_group.orbwatch_sg.id]
  # }

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

#task definition
resource "aws_ecs_task_definition" "orbwatch_task_definition" {
  family = "orbwatch-task-definition"
  requires_compatibilities = ["EC2"]
  network_mode = "awsvpc"
  cpu = 1024
  memory = 512
  task_role_arn = data.aws_iam_role.ecs_execution_role.arn
  execution_role_arn = data.aws_iam_role.ecs_execution_role.arn
  container_definitions = jsonencode([
    {
      name = "orbwatch"
      image = "706572850235.dkr.ecr.us-west-1.amazonaws.com/orbwatch:latest"
      essential = true
      cpu = 0
      portMappings = [
        {
          name = "orbwatch-80-tcp"
          containerPort = 80
          hostPort = 80
          protocol = "tcp"
          appProtocol = "http"
        }
      ]
      environment = [
        {
          name = "DB_HOST"
          value = split(":", aws_db_instance.orbwatch_db.endpoint)[0]
        },
        {
          name = "DB_USERNAME"
          value = var.db_username
        },
        {
          name = "DB_PASSWORD"
          value = var.db_password
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/orbwatch-task-definition"
          mode = "non-blocking"
          awslogs-create-group = "true"
          max-buffer-size = "25m"
          awslogs-region = "us-west-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      mountPoints = []
      volumesFrom = []
      systemControls = []
    }
  ])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }
}

#capacity provider
resource "aws_ecs_capacity_provider" "orbwatch_capacity_provider" {
  name = "orbwatch-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.orbwatch_asg.arn
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status = "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "orbwatch_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.orbwatch_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.orbwatch_capacity_provider.name]
  default_capacity_provider_strategy {
    base = 1
    weight = 100
    capacity_provider = aws_ecs_capacity_provider.orbwatch_capacity_provider.name
  }
}

#ecs service
resource "aws_ecs_service" "orbwatch_service" {
  name = "orbwatch-service"
  cluster = aws_ecs_cluster.orbwatch_cluster.id
  task_definition = aws_ecs_task_definition.orbwatch_task_definition.arn
  desired_count = 1
  
  network_configuration {
    subnets = [
      data.aws_subnet.orbwatch_subnet1.id,
      data.aws_subnet.orbwatch_subnet2.id
    ]
    security_groups = [data.aws_security_group.orbwatch_sg.id]

  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.orbwatch_capacity_provider.name
    base = 1
    weight = 100
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.orbwatch_target_group.arn
    container_name = "orbwatch"
    container_port = 80
  }
  
  depends_on = [ aws_autoscaling_group.orbwatch_asg, aws_lb_listener.orbwatch_listener ]
}
