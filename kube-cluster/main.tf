locals = {
  cluster_config = "${merge(local.default_cluster_config, var.cluster_config)}"

  cluster_values = {
    vpc_config     = "${var.vpc_config}"
    cluster_name   = "${var.name}"
    cluster_config = "${local.cluster_config}"
    kops_state     = "${var.kops_state}"
    ssh_access     = "[${join(",", var.ssh_access)}]"
    api_access     = "[${join(",", var.api_access)}]"
  }

  cluster_values_json = "${jsonencode(local.cluster_values)}"
  cluster_template    = "${path.module}/resources/cluster-template.yaml"

  out_dir           = "${path.module}/.generated"
  out_cluster_spec  = "${local.out_dir}/cluster.yaml"
  out_kubeconfig    = "${local.out_dir}/${var.name}.kubeconfig"
  out_admin_rsa_pub = "${local.out_dir}/admin-rsa.pub"
  out_config_hash   = "${local.out_dir}/${var.name}.md5"

  apiserver_retry_wait = 10

  kops_env = {
    KOPS_CLUSTER_NAME  = "${var.name}"
    KOPS_STATE_STORE   = "s3://${var.kops_state}"
    AWS_DEFAULT_REGION = "ap-southeast-1"
  }
}

resource "local_file" "cluster_admin_key" {
  filename = "${local.out_admin_rsa_pub}"
  content  = "${var.ssh_public_key}"
}

resource "local_file" "cluster_spec" {
  depends_on = ["null_resource.update_cluster"]
  filename   = "${local.out_cluster_spec}.bitch"
  content    = "${file(local.out_cluster_spec)}"
}

# Generate a shell scripts for cluster update and kube config generation. Not as nice as a Terraform provider
# but it gets the job done and saves us the need to install a custom provider.
resource "local_file" "cluster_update_sh" {
  filename = "${local.out_dir}/update-cluster.sh"

  content = <<EOF
export KOPS_CLUSTER_NAME="${var.name}"
export KOPS_STATE_STORE="s3://${var.kops_state}"
export KUBECONFIG="${local.out_kubeconfig}"

mkdir -p ${local.out_dir}

kops toolbox template --values=<( echo '${local.cluster_values_json}') --template=${local.cluster_template} --format-yaml > ${local.out_cluster_spec}
kops replace --force -f ${local.out_cluster_spec}
kops create secret sshpublickey admin -i "${local_file.cluster_admin_key.filename}"

kops update cluster --yes
kops export kubecfg

until kubectl get pod > /dev/null 2>&1; do 
  echo "Kubernetes api server not ready, will retry in ${local.apiserver_retry_wait}s"
  sleep ${local.apiserver_retry_wait}
done

echo "You need to export KUBECONFIG=${local.out_kubeconfig} to connect to your cluster."
EOF
}

# This script deletes the cluster. Using it in a destroy-time provisioner would destroy and 
# re-create the cluster each time the config is changed, so we don't include there. User is 
# expected to run the delete script manually if the cluster is to be removed.
resource "local_file" "cluster_delete_sh" {
  filename = "${local.out_dir}/delete-cluster.sh"

  content = <<EOF
export KOPS_CLUSTER_NAME="${var.name}"
export KOPS_STATE_STORE="s3://${var.kops_state}"

kops delete cluster --yes

EOF
}

# Update cluster if requested. If var.update_cluster is false (default) we skip this step and the user
# is responsible to run the cluster update script manually
resource "null_resource" "update_cluster" {
  count = "${var.update_cluster}"

  triggers = {
    update_cluster = "${md5(local_file.cluster_update_sh.content)}"
  }

  provisioner "local-exec" {
    command     = "${local_file.cluster_update_sh.filename}"
    interpreter = ["bash", "-c"]
  }

  # provisioner "local-exec" {
  #   when        = "destroy"
  #   command     = "${local_file.cluster_delete_sh.filename}"
  #   interpreter = ["bash", "-c"]
  # }
}
