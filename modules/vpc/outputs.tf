output "vpc_resources" {
    value = aws_vpc.resource_vpc
}

output "vpc_ids" {
  value = { for k, v in aws_vpc.resource_vpc : k => v.id }
}

output "vpc_map" {
  value= local.vpc_map
}
output "subnet_set" {
    value = local.subnet_set
}

output "subnet_build" {
    value = local.subnet_build
  
}


output "subnet_flat" {
    value = local.subnet_flat
}

output "subnet_resources" {
  value= aws_subnet.resource_subnet
}

