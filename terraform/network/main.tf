resource "aws_vpc" "orbwatch_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "orbwatch-vpc"
  }
}

resource "aws_subnet" "orbwatch_subnet1" {
  vpc_id = aws_vpc.orbwatch_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-1a"
  tags = {
    Name = "orbwatch-subnet1"
  }
}

resource "aws_subnet" "orbwatch_subnet2" {
  vpc_id = aws_vpc.orbwatch_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1c"
  tags = {
    Name = "orbwatch-subnet2"
  }
}

resource "aws_internet_gateway" "orbwatch_igw" {
  vpc_id = aws_vpc.orbwatch_vpc.id
  tags = {
    Name = "orbwatch-igw"
  }
}

resource "aws_route_table" "orbwatch_route_table" {
  vpc_id = aws_vpc.orbwatch_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.orbwatch_igw.id
  }
  tags = {
    Name = "orbwatch-route-table"
  }

}

resource "aws_route_table_association" "orbwatch_route_table_association1" {
  subnet_id = aws_subnet.orbwatch_subnet1.id
  route_table_id = aws_route_table.orbwatch_route_table.id
}

resource "aws_route_table_association" "orbwatch_route_table_association2" {
  subnet_id = aws_subnet.orbwatch_subnet2.id
  route_table_id = aws_route_table.orbwatch_route_table.id
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.orbwatch_vpc.id

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

  tags = {
    Name = "db-sg"
  }
}

resource "aws_security_group" "orbwatch_sg" {
  vpc_id = aws_vpc.orbwatch_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "orbwatch-sg"
  }
}

