terraform {
  required_version = ">=0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.35.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.7.2"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "cluster_dev" {
  source            = "../modules/aws"
  redpanda_cluster  = true
  clickhouse_cluster = false
  enable_monitoring = false
}