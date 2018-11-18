output "vpc_config" {
  value = "${module.cluster_vpc.vpc_config}"
}

# output "cluster_name" {
#   value = "${local.cluster_name}"
# }
# output "kops_state" {
#   value = "${local.kops_state}"
# }
output "kubeconfig" {
  value = "${module.cluster.kubeconfig}"
}

output "scripts" {
  value = "${module.cluster.scripts}"
}

# output "cluster_spec" {
#   value = "${module.cluster.cluster_spec}"
# }
output "ssh_keys" {
  value = {
    public_key  = "${local_file.ssh_public_key.filename}"
    private_key = "${local_file.ssh_private_key.filename}"
  }
}
