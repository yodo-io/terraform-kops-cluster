output "cluster_name" {
  value = "${var.name}"
}

output "name" {
  value = "${var.name}"
}

output "kubeconfig" {
  description = "Location of kubeconfig file for this cluster"
  value       = "${local.out_kubeconfig}"
}

output "cluster_spec" {
  description = "Location of the rendered cluster spec"
  value       = "${local.out_cluster_spec}"
}

output "scripts" {
  description = "Generated scripts for cluster maintenance"

  value = {
    update_cluster = "${local_file.cluster_update_script.filename}"
    delete_cluster = "${local_file.cluster_delete_script.filename}"
  }
}
