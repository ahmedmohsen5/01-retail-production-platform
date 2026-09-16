variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"

}

variable "public_subnet_cidrs" {
  type = map(object({
    cidr_block        = string
    availability_zone = number
  }))
  default = {
    "subnet-1" = {
      cidr_block        = "10.0.0.0/24"
      availability_zone = 0
    }
    "subnet-2" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = 1
    }
  }
}

variable "private_subnet_cidrs" {
  type = map(object({
    cidr_block        = string
    availability_zone = number
  }))
  default = {
    "subnet-1" = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = 0
    }
    "subnet-2" = {
      cidr_block        = "10.0.11.0/24"
      availability_zone = 1
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
data "aws_availability_zones" "available" {
  state = "available"
}


