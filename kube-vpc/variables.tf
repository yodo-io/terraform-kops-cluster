variable "vpc_name" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "tags" {
  description = "Additional tags to attach to each resource"
  type        = "map"
  default     = {}
}

variable "vpc_cidr" {
  type    = "string"
  default = "10.0.0.0/16"
}

variable "num_subnets" {
  description = "Number of subnets to use. Must be an odd number and smaller or equal number of AZ in selected region"
  default     = 3
}

# FIXME: calculate these from vpc_cidr
variable "vpc_public_subnets" {
  default = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

variable "vpc_private_subnets" {
  default = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "database_subnets" {
  default = ["10.1.51.0/24", "10.1.52.0/24", "10.1.53.0/24"]
}

variable "http_ingress_ips" {
  default = ["0.0.0.0/0"]
}
