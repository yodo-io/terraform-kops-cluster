data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

locals {
  availability_zones = "${slice(data.aws_availability_zones.available.names,0,var.num_subnets)}"

  public_subnets   = ["${slice(local.public_subnet_cidrs, 0, length(local.availability_zones))}"]
  private_subnets  = ["${slice(local.private_subnet_cidrs, 0, length(local.availability_zones))}"]
  database_subnets = ["${slice(local.database_subnet_cidrs, 0, length(local.availability_zones))}"]

  base_tags = {
    Terraform         = "managed"
    KubernetesCluster = "${var.cluster_name}"
  }

  tags = "${merge(var.tags, local.base_tags)}"
}

resource "tls_private_key" "admin_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "admin_ssh_key" {
  key_name   = "${var.cluster_name}-admin"
  public_key = "${tls_private_key.admin_ssh_key.public_key_openssh}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.46.0"

  name = "${var.vpc_name}"
  cidr = "${var.vpc_cidr}"
  azs  = ["${local.availability_zones}"]

  private_subnets  = ["${local.private_subnets}"]
  public_subnets   = ["${local.public_subnets}"]
  database_subnets = ["${local.database_subnets}"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  propagate_private_route_tables_vgw = true
  propagate_public_route_tables_vgw  = true

  tags = "${merge(
    local.tags, 
    map("kubernetes.io/cluster/${var.cluster_name}", "shared"))
  }"

  // Tags required by k8s to launch services on the right subnets
  // SubnetType tag is set by kops, so proactively included here
  private_subnet_tags = "${merge(
    local.tags,
    map(
      "kubernetes.io/role/internal-elb", true, 
      "SubnetType", "Private"
    )
  )}"

  public_subnet_tags = "${merge(
    local.tags,
    map(
      "kubernetes.io/role/elb", true, 
      "SubnetType", "Utility"
    )
  )}"

  database_subnet_tags = "${merge(
    map("SubnetType", "Database")
  )}"
}
