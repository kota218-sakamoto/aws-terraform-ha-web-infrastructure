variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ha-web"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1a_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_1c_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "app_subnet_1a_cidr" {
  type    = string
  default = "10.0.11.0/24"
}

variable "app_subnet_1c_cidr" {
  type    = string
  default = "10.0.12.0/24"
}

variable "db_subnet_1a_cidr" {
  type    = string
  default = "10.0.21.0/24"
}

variable "db_subnet_1c_cidr" {
  type    = string
  default = "10.0.22.0/24"
}

variable "availability_zone_1a" {
  description = "Availability Zone 1"
  type        = string
  default     = "ap-northeast-1a"
}

variable "availability_zone_1c" {
  description = "Availability Zone 2"
  type        = string
  default     = "ap-northeast-1c"
}
