terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIAQZFSU2W5CUJLTTWV"
  secret_key = "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"
}

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "test"
  }
}

resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test.id

  tags = {
    Name = "test_igw"
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_1a"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_1b"
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private_1a"
  }
}

resource "aws_subnet" "private_1b" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "private_1b"
  }
}


resource "aws_route_table" "public_rt1" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }
  
  tags = {
    Name = "public_rt1"
  }
}

resource "aws_route_table_association" "public_rtsa1" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public_rt1.id
}

resource "aws_eip" "ngw_eip" {
  depends_on = [
    aws_route_table_association.public_rtsa1
  ]
  vpc = true
}

resource "aws_route_table" "public_rt2" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }


  tags = {
    Name = "public_rt2"
  }
}


resource "aws_route_table_association" "public_rtsa2" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public_rt2.id
}

resource "aws_route_table" "private_rt1" {
  vpc_id = aws_vpc.test.id
  depends_on = [
    aws_nat_gateway.test_ngw
  ]

  route {
    cidr_block = "10.0.3.0/24"
    nat_gateway_id = aws_nat_gateway.test_ngw.id
    }


  tags = {
    Name = "private_rt1"
  }
}

resource "aws_route_table_association" "private_rtsa1" {
    depends_on = [
    aws_route_table.private_rt1
  ]
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_rt1.id
}

resource "aws_route_table" "private_rt2" {
  vpc_id = aws_vpc.test.id
  depends_on = [
    aws_nat_gateway.test_ngw
  ]

  route {
    cidr_block = "10.0.4.0/24"
    nat_gateway_id = aws_nat_gateway.test_ngw.id
    }


  tags = {
    Name = "private_rt2"
  }
}

resource "aws_route_table_association" "private_rtsa2" {
    depends_on = [
    aws_route_table.private_rt2
  ]
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private_rt2.id
}

resource "aws_nat_gateway" "test_ngw" {
  depends_on = [
    aws_eip.ngw_eip
  ]

  
  allocation_id = aws_eip.ngw_eip.id
  
  
  subnet_id = aws_subnet.public_1a.id
  tags = {
    Name = "test_ngw"
  }
}



resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.test.id

  ingress {
    description      = "https from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["10.0.1.0/24"]
  }

  ingress {
    description      = "https from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["10.0.2.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all"
  }
}