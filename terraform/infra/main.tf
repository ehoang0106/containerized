#database

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.orbwatch_subnet1.id, aws_subnet.orbwatch_subnet2.id]
}

resource "aws_db_instance" "orbwatch_db" {
  identifier = "orbwatch-db"
  provider = aws
  allocated_storage = 20
  db_name = "orbwatchdb"
  engine = "mysql"
  engine_version = "8.0.40"
  instance_class = "db.t3.micro"
  username = var.db_username
  password = var.db_password
  parameter_group_name = "default.mysql8.0"
  publicly_accessible = true
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
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
  key_name = "orb-key"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.orbwatch_sg.id]
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

  user_data = base64decode(data.template_file.user_data.rendered)

  tags = {
    Name = "orbwatch-launch-template"
  }
}