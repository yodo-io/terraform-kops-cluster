# Terraforms kubernetes provider seems to be a rather buggy mess, so the best option we seem 
# to have right now is to generate a custom bootstrap script and run it with a local provisioner
# It would be nice if we could get at least helm tho. Using local-exec has an additional benefit 
# though: we can just define our kubeconfig inline and don't need to worry about a provider config
# resource "null_resource" "init_tiller" {
#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command = <<EOF
# export KUBECONFIG="${var.kubeconfig}"
# ${var.bin_kubectl} apply -f "${path.module}/resources/rbac-config.tf"
# ${var.bin_helm} init --service-account tiller
# EOF
#   }
# }

