data "aws_caller_identity" "current" {}

locals {
  full_name    = "${var.name}-${var.env}"
  kops_state   = "${local.full_name}-kops-state-${data.aws_caller_identity.current.account_id}"
  cluster_name = "${local.full_name}.${var.domain}"

  tags = {
    Name        = "${var.name}"
    Environment = "${var.env}"
  }
}

# Kops state bucket - just creating a plain S3 bucket here, for production use you may want to enable
# versioning and server side encryption using a custom KMS key.
resource "aws_s3_bucket" "kops_state" {
  bucket        = "${local.kops_state}"
  acl           = "private"
  force_destroy = true
  tags          = "${local.tags}"
}

# Optionated wrapper around terraform-aws-modules/vpc/aws, producing a VPC with 3x3 subnets 
# across 3 AZ and additional resources like an EC2 keypair and a security group. The resulting
# VPC config is output in a format that can easilty be consumed by the cluster module.
# 
# There is no hard dependency, you can just as well generate your own VPC or use an existing one
# and pass the relevant information to the `kube-cluster` module.
module "cluster_vpc" {
  source = "../kube-vpc"

  vpc_name = "${local.full_name}"
  vpc_cidr = "10.50.0.0/16"

  cluster_name = "${local.cluster_name}"
  tags         = "${local.tags}"
}

# Bootstraps the cluster itself. For now just a PoC using null_resource with local provisioner but it 
# has drawbacks, e.g. it can't delete the resources it generated. Might need to build a proper provider
module "cluster" {
  source = "../kube-cluster"
  name   = "${local.cluster_name}"

  vpc_config     = "${module.cluster_vpc.vpc_config}"
  kops_state     = "${local.kops_state}"
  ssh_public_key = "${module.cluster_vpc.ssh_keys["public_key_openssh"]}"

  update_cluster = true
}

# Dump the generated SSH keys into file system for troubleshooting.
# TODO: move into kube_config module
resource "local_file" "ssh_public_key" {
  filename = "${path.root}/.generated/tls/${local.cluster_name}.pub"
  content  = "${module.cluster_vpc.ssh_keys["public_key_openssh"]}"
}

resource "local_file" "ssh_private_key" {
  filename = "${path.root}/.generated/tls/${local.cluster_name}-rsa"
  content  = "${module.cluster_vpc.ssh_keys["private_key_pem"]}"
}

# module "kube_config" {
#   source     = "./kube-config"
#   output_dir = "${path.module}/.generated"


#   # cluster must exist, so make sure to use a reference to the cluster module!
#   cluster_name = "${module.cluster.cluster_name}"
#   kops_state   = "${local.kops_state}"


#   ssh_keys = "${module.cluster_vpc.ssh_keys}"
# }


# Bootstrap the cluster using helm 
# module "cluster_bootstrap" {
#   source     = "../kube-bootstrap"
#   kubeconfig = "${module.cluster.kubeconfig}"


#   # will be used to configure helm & kubernetes provider


#   #   datadog = {
#   #     enabled = true
#   #     api_key = ""
#   #   }


#   #   fluentd = {
#   #     enabled     = true
#   #     output_type = "loggly"
#   #   }


#   # cluster_autoscaler = {
#   #   enabled = true
#   # }
#   # namespaces = [
#   #   "backend",
#   #   "logistics",
#   #   "...",
#   # ]
# }

