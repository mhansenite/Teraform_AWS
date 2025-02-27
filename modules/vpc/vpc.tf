variable "master" {}
variable "vpcs" {}

locals{
    vpc_map = {
        for k, v in var.vpcs: k=> {
            "vpc_key"="${split(".",v.vpc_cidr_block).0}-${split(".",v.vpc_cidr_block).1}",
            "workspace"= v.workspace,
            "subnet_zones"=v.subnet_zones,
            "tag_purpose"=v.tag_purpose,
            "vpc_cidr_block"=v.vpc_cidr_block
        }if v.workspace == terraform.workspace
         }

    subnet_build={for k, v in local.vpc_map : k => { 
        for k1,v1 in v.subnet_zones: "${k}-${v1.network}" => {
            "name"="${v1.name}-${v.vpc_key}-${v1.network}",
            "subnet_key"="${v.vpc_key}-${v1.network}",
            "subnet_zones"=v1.name,
            "avl_zone"=v1.avl_zone
            "vpc_key"=v.vpc_key,
            "type"=v1.type
            "workspace"=v.workspace,
            "vpc_cidr" = v.vpc_cidr_block,
            "cidr"=cidrsubnet(v.vpc_cidr_block,8,v1.network)
            }if v.workspace == terraform.workspace
        }

    }   
    subnet_flat=merge([for k, v in local.subnet_build:{for v1 in v: v1.name => v1}]...)
    subnet_set =[for k, v in local.subnet_flat: v]
}


########################################################################
#Vpcs
########################################################################

resource "aws_vpc" "resource_vpc" {
for_each =  {for k, v in local.vpc_map: v.vpc_key => v if v.workspace == terraform.workspace}
  cidr_block                       = each.value.vpc_cidr_block
  # enable_classiclink               = "false"
  # enable_classiclink_dns_support   = "true"
  enable_dns_hostnames             = "true"
  enable_dns_support               = "true"
  instance_tenancy                 = "default"

  tags = {
    Name = "${each.value.workspace}-${var.master.convention}-${each.key}-VPC"
    Purpose = "${each.value.tag_purpose}"
    Workspace = "${each.value.workspace}"
  }

  tags_all = {
    Name = "${each.value.workspace}-${var.master.convention}-${each.key}-VPC"
    Purpose = "${each.value.tag_purpose}"
    Workspace = "${each.value.workspace}"
  }
}


########################################################################
#Gateways
########################################################################

resource "aws_internet_gateway" "resource_igw" {
    for_each =  {for k, v in local.vpc_map: v.vpc_key=> v if v.workspace == terraform.workspace}
  vpc_id = resource.aws_vpc.resource_vpc[each.key].id
  tags = {
    Name = "${each.value.workspace}-${var.master.convention}-${each.key}-GW"
    Workspace = "${each.value.workspace}"
  }

  tags_all = {
    Name = "${each.value.workspace}-${var.master.convention}-${each.key}-GW"
    Workspace = "${each.value.workspace}"
  }
  
}


########################################################################
#Subnets
########################################################################

resource "aws_subnet" "resource_subnet" {
  for_each = {for k, v in local.subnet_set: v.subnet_key=> v if v.workspace == terraform.workspace }
  vpc_id = resource.aws_vpc.resource_vpc[each.value.vpc_key].id                  
  cidr_block                                     = each.value.cidr
  private_dns_hostname_type_on_launch            = "ip-name"
  availability_zone                             = "${var.master.region}${each.value.avl_zone}"

  tags = {
    Name = "${terraform.workspace}-${var.master.convention}-${each.value.name}-SN"
     Type=each.value.type
  }

  tags_all = {
    Name = "${terraform.workspace}-${var.master.convention}-${each.value.name}-SN"
    Workspace = "${each.value.workspace}"
    Type=each.value.type
    #Name = "${var.infa.lane}-${var.master.company}-${each.value.name}-SN"
  }
  depends_on = [ aws_vpc.resource_vpc ]
 }


########################################################################
#Prefix_Lists
########################################################################


 resource "aws_ec2_managed_prefix_list" "resource_prefix_lists_vpc" {
    for_each =  {for k, v in local.vpc_map: v.vpc_key => v if v.workspace == terraform.workspace}
    name           = "${each.value.workspace}-${each.key}-${var.master.convention}-PL"
    address_family = "IPv4"
    max_entries    = 5

    entry {
        cidr        = each.value.vpc_cidr_block
        description = "${each.value.vpc_cidr_block}-VPC"
    }
 
    tags = {
        Name = "${each.value.workspace}-${each.key}-${var.master.convention}"
        Workspace = "${each.value.workspace}"
    }
}

 resource "aws_ec2_managed_prefix_list" "resource_prefix_lists_subnets" {
    for_each = {for k, v in local.subnet_set: k=> v if v.workspace == terraform.workspace}
    name           = "${terraform.workspace}-${each.value.name}-${var.master.convention}-PL"
    address_family = "IPv4"
    max_entries    = 5

    entry {
        cidr        = each.value.cidr
        description = "${each.value.name}-SN"
    }
 
    tags = {
        Name = "${terraform.workspace}-${var.master.convention}-${each.value.name}"
        Workspace = "${each.value.workspace}"
    }
}

data "aws_subnets" "selected" {
  filter {
    name   = "tag:Type"
    values = ["DB"] # insert values here
  }
}
output "working" {
  value = data.aws_subnets.selected
}

# resource "aws_db_subnet_group" "database_subnets" {
#     for_each = {for k, v in local.subnet_set: k=> v if v.workspace == terraform.workspace || v.subnet_zones == "DB"? "true":"false"}

#     name       = lower("${each.value.workspace}-${var.master.convention}-db-zone_${each.value.name}")
#     description = "DatabaseZone for ${each.value.workspace}-${var.master.convention}-${each.value.name}"
#     subnet_ids = [resource.aws_subnet.resource_subnet[each.value.subnet_key].id]

#     tags = {
#         Name = "${each.value.workspace}-${var.master.convention}-db-zone_${each.value.name}-SN"
#     }
#     depends_on = [ aws_subnet.resource_subnet ]
# }