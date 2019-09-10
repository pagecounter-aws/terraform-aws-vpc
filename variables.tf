variable "vpc_cidr_block" {
  default     = "192.168.0.0/22"
  description = "VPC cidr block"
}

variable "vpc_subnet_cidr_blocks" {
  type = list(string)
  default = [
    "192.168.0.0/24",
    "192.168.1.0/24",
    "192.168.2.0/24",
    "192.168.3.0/24",
  ]
  description = "VPC subnet cidr blocks"
}

variable "vpc_tags" {
  type        = map(string)
  description = "VPC tag"

  default = {
    Name = "VPC"
  }
}

variable "ssh_port" {
  default = 22
}

variable "ssh_cidr" {
  default = "0.0.0.0/0"
}

variable "icmp_cidr" {
  default = "0.0.0.0/0"
}
