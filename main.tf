terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider for us-east-1
provider "aws" {
  region = "us-east-1"
}

# Alias provider for us-west-2
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# -------------------
# Variables
# -------------------

variable "instance_type" {
  default = "t2.micro"
}

# Key pairs for each region
variable "east_key_name" {
  description = "The name of the EC2 Key Pair for us-east-1"
  default     = "us-east-1-key-pair"  # Replace with your actual key for us-east-1
}

variable "west_key_name" {
  description = "The name of the EC2 Key Pair for us-west-2"
  default     = "us-west-2-key-pair"  # Replace with your actual key for us-west-2
}

# -------------------
# East Region Resources
# -------------------

resource "aws_vpc" "east_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "east-vpc"
  }
}

resource "aws_subnet" "east_subnet" {
  vpc_id            = aws_vpc.east_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "east-subnet"
  }
}

resource "aws_security_group" "east_sg" {
  name        = "east-sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.east_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "east_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "east_instance" {
  ami                         = data.aws_ami.east_ami.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.east_subnet.id
  key_name                    = var.east_key_name  # Using the key for us-east-1
  vpc_security_group_ids      = [aws_security_group.east_sg.id]

  tags = {
    Name = "EastInstance"
  }
}

# -------------------
# West Region Resources
# -------------------

resource "aws_vpc" "west_vpc" {
  provider   = aws.west
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "west-vpc"
  }
}

resource "aws_subnet" "west_subnet" {
  provider          = aws.west
  vpc_id            = aws_vpc.west_vpc.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "west-subnet"
  }
}

resource "aws_security_group" "west_sg" {
  provider    = aws.west
  name        = "west-sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.west_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "west_ami" {
  provider    = aws.west
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "west_instance" {
  provider                  = aws.west
  ami                       = data.aws_ami.west_ami.id
  instance_type             = var.instance_type
  subnet_id                 = aws_subnet.west_subnet.id
  key_name                  = var.west_key_name  # Using the key for us-west-2
  vpc_security_group_ids    = [aws_security_group.west_sg.id]

  tags = {
    Name = "WestInstance"
  }
}
