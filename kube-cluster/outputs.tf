output "cluster_name" {
  value = "${var.name}"
}

output "name" {
  value = "${var.name}"
}

output "kubeconfig" {
  description = "Location of kubeconfig file for this cluster. Note that this sadly _cannot_ be used as input for Terraform provider configuration blocks"
  value       = "${local.out_kubeconfig}"
}

output "cluster_spec" {
  description = "Location of the rendered cluster spec"
  value       = "${local.out_cluster_spec}"
}

output "scripts" {
  description = "Generated scripts for cluster maintenance"

  value = {
    update_cluster = "${local_file.cluster_update_sh.filename}"
    delete_cluster = "${local_file.cluster_delete_sh.filename}"
  }
}
