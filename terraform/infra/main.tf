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