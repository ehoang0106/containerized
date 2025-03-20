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
  cidr_block = "10.0.0.0/20"
  availability_zone = "us-west-1a"

  tags = {
    Name = "db_subnet_1"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id = aws_vpc.db_vpc.id
  cidr_block = "10.0.1.0/20"
  availability_zone = "us-west-1b"
  availability_zone_id = "us-west-1c"

  tags = {
    Name = "db_subnet_2"
  }
}