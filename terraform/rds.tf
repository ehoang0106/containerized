resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
}

resource "aws_db_instance" "db_instance" {
  identifier = "mydb"
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
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  tags = {
    Name = "mydb"
  }
}