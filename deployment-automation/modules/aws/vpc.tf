module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"
  name    = "redpanda_vpc"
  cidr    = var.cidr
  count   = var.redpanda_cluster ? 1 : 0


  azs = data.aws_availability_zones.available.names
  private_subnets = [
    cidrsubnet(var.cidr, 8, 11),
    cidrsubnet(var.cidr, 8, 12),
    cidrsubnet(var.cidr, 8, 13)
  ]
  public_subnets = [
    cidrsubnet(var.cidr, 8, 1),
    cidrsubnet(var.cidr, 8, 2),
    cidrsubnet(var.cidr, 8, 3)
  ]

  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  enable_flow_log                      = true

  enable_nat_gateway   = true
  enable_dns_hostnames = true

  tags = local.tags
}

data "aws_availability_zones" "available" {}
