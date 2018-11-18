# Precalculated CIDR blocks for subnets, will be sliced to the required length based
# on number of subnets requested. Note that we can only use up to /24 CIDR blocks
# We only support one subnet per AZ and there are no zones with more than 10 AZs
locals {
  public_subnet_cidrs = [
    "${cidrsubnet(var.vpc_cidr, 8, 0)}",
    "${cidrsubnet(var.vpc_cidr, 8, 1)}",
    "${cidrsubnet(var.vpc_cidr, 8, 2)}",
    "${cidrsubnet(var.vpc_cidr, 8, 3)}",
    "${cidrsubnet(var.vpc_cidr, 8, 4)}",
    "${cidrsubnet(var.vpc_cidr, 8, 5)}",
    "${cidrsubnet(var.vpc_cidr, 8, 6)}",
    "${cidrsubnet(var.vpc_cidr, 8, 7)}",
    "${cidrsubnet(var.vpc_cidr, 8, 8)}",
  ]

  private_subnet_cidrs = [
    "${cidrsubnet(var.vpc_cidr, 8, 50)}",
    "${cidrsubnet(var.vpc_cidr, 8, 51)}",
    "${cidrsubnet(var.vpc_cidr, 8, 52)}",
    "${cidrsubnet(var.vpc_cidr, 8, 53)}",
    "${cidrsubnet(var.vpc_cidr, 8, 54)}",
    "${cidrsubnet(var.vpc_cidr, 8, 55)}",
    "${cidrsubnet(var.vpc_cidr, 8, 56)}",
    "${cidrsubnet(var.vpc_cidr, 8, 57)}",
    "${cidrsubnet(var.vpc_cidr, 8, 58)}",
  ]

  database_subnet_cidrs = [
    "${cidrsubnet(var.vpc_cidr, 8, 100)}",
    "${cidrsubnet(var.vpc_cidr, 8, 101)}",
    "${cidrsubnet(var.vpc_cidr, 8, 102)}",
    "${cidrsubnet(var.vpc_cidr, 8, 103)}",
    "${cidrsubnet(var.vpc_cidr, 8, 104)}",
    "${cidrsubnet(var.vpc_cidr, 8, 105)}",
    "${cidrsubnet(var.vpc_cidr, 8, 106)}",
    "${cidrsubnet(var.vpc_cidr, 8, 107)}",
    "${cidrsubnet(var.vpc_cidr, 8, 108)}",
  ]
}
