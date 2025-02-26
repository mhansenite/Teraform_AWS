variable "permissions" {}
variable "vpcs" {}

#use modules and outputs to have a single master variable that we can call
module "variables" {
  source = "../configs/variables"
}

provider "aws" {
  region = module.variables.master.region
}

module "iam" {
  source      = "../modules/iam"
  master      = module.variables.master
  permissions = var.permissions
}

module "vpcs" {
  source = "../modules/vpc"
  master = module.variables.master
  vpcs   = var.vpcs
}

module "gateways" {
  source = "../modules/gateways"
  
  master           = module.variables.master
  env             = terraform.workspace
  vpc_id          = module.vpcs.vpc_resources["${split(".",var.vpcs[0].vpc_cidr_block).0}-${split(".",var.vpcs[0].vpc_cidr_block).1}"].id
  public_subnet_id = [for k, v in module.vpcs.subnet_resources : v.id if contains([for s in var.vpcs[0].subnet_zones : s.type if s.type == "APP"], "APP")][0]
}

module "peering" {
  count  = length(var.vpcs) > 1 ? 1 : 0
  source = "../modules/peering"
  
  master            = module.variables.master
  env              = terraform.workspace
  requester_vpc_id = module.vpcs.vpc_resources["${split(".",var.vpcs[0].vpc_cidr_block).0}-${split(".",var.vpcs[0].vpc_cidr_block).1}"].id
  accepter_vpc_id  = module.vpcs.vpc_resources["${split(".",var.vpcs[1].vpc_cidr_block).0}-${split(".",var.vpcs[1].vpc_cidr_block).1}"].id
}

module "alb" {
  source = "../modules/alb"
  
  master   = module.variables.master
  env      = terraform.workspace
  app_name = "main"
  vpc_id   = module.vpcs.vpc_resources["${split(".",var.vpcs[0].vpc_cidr_block).0}-${split(".",var.vpcs[0].vpc_cidr_block).1}"].id
  
  # Get all APP type subnet IDs
  subnet_ids = [
    for k, v in module.vpcs.subnet_resources : v.id 
    if contains([for s in var.vpcs[0].subnet_zones : s.type if s.type == "APP"], "APP")
  ]
}

module "security" {
  source = "../modules/security"
  
  master   = module.variables.master
  env      = terraform.workspace
  app_name = "base"
  vpc_id   = module.vpcs.vpc_resources["${split(".",var.vpcs[0].vpc_cidr_block).0}-${split(".",var.vpcs[0].vpc_cidr_block).1}"].id
  
  security_groups = {
    base = {
      name        = "base-sg"
      description = "Base security group for VPC"
      ingress_rules = []
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
    }
  }
}
