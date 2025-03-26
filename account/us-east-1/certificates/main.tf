locals {
  certificate_module_location = "git::git@github.com:Fydon/terragrunt.git//module/certificate"
}

module "certificate" {
  source = local.certificate_module_location
}
