module "cluster_dev" {
  source           = "../modules/aws"
  redpanda_cluster = true
  vpc              = true
}