# VPC
output "vpc_config" {
  value = {
    name       = "${var.vpc_name}"
    vpc_id     = "${module.vpc.vpc_id}"
    cidr_block = "${module.vpc.vpc_cidr_block}"

    region             = "${data.aws_region.current.name}"
    availability_zones = ["${local.availability_zones}"]

    natgw_ids     = "${module.vpc.natgw_ids}"
    default_sg_id = "${module.vpc.default_security_group_id}"

    public_subnet_ids = ["${module.vpc.public_subnets}"]
    public_rtb_ids    = ["${module.vpc.public_route_table_ids}"]

    private_subnet_ids = ["${module.vpc.private_subnets}"]
    private_rtb_ids    = ["${module.vpc.private_route_table_ids}"]

    database_subnet_ids = ["${module.vpc.database_subnets}"]
    database_rtb_ids    = ["${module.vpc.database_route_table_ids}"]
  }
}

output "ssh_keys" {
  sensitive = true

  value = {
    public_key_openssh = "${tls_private_key.admin_ssh_key.public_key_openssh}"
    public_key_pem     = "${tls_private_key.admin_ssh_key.public_key_pem}"
    private_key_pem    = "${tls_private_key.admin_ssh_key.private_key_pem}"
  }
}
