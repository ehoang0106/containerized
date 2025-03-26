data "aws_security_group" "orbwatch_sg" {
  filter {
    name = "tag:Name"
    values = ["orbwatch-sg"]
  }
}

data "aws_security_group" "db_sg" {
  filter {
    name = "tag:Name"
    values = ["db-sg"]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/userdata.tftpl")
}

data "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_vpc" "orbwatch_vpc" {
  filter {
    name = "tag:Name"
    values = ["orbwatch-vpc"]
  }
}

data "aws_subnet" "orbwatch_subnet1" {
  filter {
    name = "tag:Name"
    values = ["orbwatch-subnet1"]
  }
}

data "aws_subnet" "orbwatch_subnet2" {
  filter {
    name = "tag:Name"
    values = ["orbwatch-subnet2"]
  }
}

