locals {
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  region               = local.region_vars.locals.region
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.region}"
}
EOF
}

inputs = merge(
  local.region_vars.locals,
)