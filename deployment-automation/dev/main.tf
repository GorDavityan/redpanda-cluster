module "cluster_dev" {
  source = "../modules/aws"
  aws_region = "us-west-2"
  tiered_storage_enabled = true
}