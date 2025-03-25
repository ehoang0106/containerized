data "aws_security_group" "orbwatch_sg" {
  name = "orbwatch_sg"
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