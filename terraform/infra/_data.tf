data "aws_security_group" "orbwatch_sg" {
  name = "orbwatch_sg"
}
data "aws_security_group" "db_sg" {
  name = "db_sg"
}
data "local_file" "orbwatch_sg" {
  filename = "${path.module}/userdata.tftpl"
}

data "template_file" "user_data" {
  template = data.local_file.orbwatch_sg.content
}

data "aws_ami_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_vpc" "orbwatch_vpc" {
  filter {
    name = "tag:Name"
    values = ["orbwatch_vpc"]
  }
}

data "aws_subnet" "orbwatch_subnet1" {
  filter {
    name = "tag:Name"
    values = ["orbwatch_subnet1"]
  }
}

data "aws_subnet" "orbwatch_subnet2" {
  filter {
    name = "tag:Name"
    values = ["orbwatch_subnet2"]
  }
}

