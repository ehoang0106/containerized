resource "aws_vpc" "db_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "db_vpc"
  }
}

resource "aws_subnet" "db_subnet_1" {
  vpc_id = aws_vpc.db_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "db_subnet_1"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id = aws_vpc.db_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1c"

  tags = {
    Name = "db_subnet_2"
  }
}

resource "aws_internet_gateway" "db_igw" {
  vpc_id = aws_vpc.db_vpc.id

  tags = {
    Name = "db_igw"
  }
}

resource "aws_route_table" "db_route_table" {
  vpc_id = aws_vpc.db_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.db_igw.id
  }

  tags = {
    Name = "db_route_table"
  }
}

resource "aws_route_table_association" "db_route_table_association_1" {
  subnet_id = aws_subnet.db_subnet_1.id
  route_table_id = aws_route_table.db_route_table.id
}

resource "aws_route_table_association" "db_route_table_association_2" {
  subnet_id = aws_subnet.db_subnet_2.id
  route_table_id = aws_route_table.db_route_table.id
}

resource "aws_security_group" "db_security_group" {
  vpc_id = aws_vpc.db_vpc.id

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}