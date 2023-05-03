variable "redpanda_cluster" {
  description = "create or not redpanda cluster"
  type        = bool
  default     = true
}

variable "clickhouse_cluster" {
  description = "create or not clickhouse cluster"
  type        = bool
  default     = false
}

variable "cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "cidr block"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to deploy the infrastructure on"
  default     = "us-west-2"
}

variable "vpc_tag" {
  type        = map(string)
  description = "vpc tag"
  default = {
    "vpc" = "redpanda"
  }
}

variable "availability_zone" {
  description = "The AWS AZ to deploy the infrastructure on"
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
  type        = list(string)
}

variable "client_distro" {
  type        = string
  description = "Linux distribution to use for clients."
  default     = "ubuntu-jammy"
}

variable "client_instance_type" {
  type        = string
  description = "Default client instance type to create"
  default     = "m5n.2xlarge"
}

variable "deployment_prefix" {
  description = "The prefix for the instance name (defaults to {random uuid}-{timestamp})"
  type        = string
  default     = ""
}

variable "distro" {
  type        = string
  description = "The default distribution to base the cluster on"
  default     = "ubuntu-jammy"
}

variable "enable_monitoring" {
  description = "Setup a prometheus/grafana instance"
  type        = bool
  default     = true
}

## It is important that device names do not get duplicated on hosts, in rare circumstances the choice of nodes * volumes can result in a factor that causes duplication. Modify this field so there is not a common factor.
## Please pr a more elegant solution if you have one.
variable "ec2_ebs_device_names" {
  type        = list(string)
  description = "Device names for EBS volumes"
  default = [
    "/dev/xvdba",
    "/dev/xvdbb",
    "/dev/xvdbc",
    "/dev/xvdbd",
    "/dev/xvdbe",
    "/dev/xvdbf",
    "/dev/xvdbg",
    "/dev/xvdbh",
    "/dev/xvdbi",
    "/dev/xvdbj",
    "/dev/xvdbk",
    "/dev/xvdbl",
    "/dev/xvdbm",
    "/dev/xvdbn",
    "/dev/xvdbo",
    "/dev/xvdbp",
    "/dev/xvdbq",
    "/dev/xvdbr",
    "/dev/xvdbs",
    "/dev/xvdbt",
    "/dev/xvdbu",
    "/dev/xvdbv",
    "/dev/xvdbw",
    "/dev/xvdbx",
    "/dev/xvdby",
    "/dev/xvdbz"
  ]
}

variable "ec2_ebs_volume_count" {
  type        = number
  description = "Number of EBS volumes to attach to each Redpanda node       esi default@ arji 1 dnel"
  default     = 0
}

variable "ec2_ebs_volume_iops" {
  type        = number
  description = "IOPs for GP3 Volumes"
  default     = 16000
}

variable "ec2_ebs_volume_size" {
  type        = number
  description = "Size of each EBS volume"
  default     = 100
}

variable "ec2_ebs_volume_throughput" {
  type        = number
  description = "Throughput per volume in MiB"
  default     = 250
}

variable "ec2_ebs_volume_type" {
  type        = string
  description = "EBS Volume Type (gp3 recommended for performance)"
  default     = "gp3"
}

variable "ha" {
  description = "Whether to use placement groups to create an HA topology          highly available lini Enable high availability, which ensures each node is on a separate rack and the cluster is rack-aware  "
  type        = bool
  default     = true
}

variable "instance_type" {
  type        = string
  description = "Default redpanda instance type to create"
  default     = "i3.2xlarge"
}

variable "clickhouse_instance_type" {
  type        = string
  description = "Default redpanda instance type to create"
  default     = "m5n.4xlarge"
}

variable "machine_architecture" {
  type        = string
  description = "Architecture used for selecting the AMI - change this if using ARM based instances"
  default     = "x86_64"
}

variable "prometheus_instance_type" {
  type        = string
  description = "Instant type of the prometheus/grafana node"
  default     = "c5.2xlarge"
}

variable "cluster_ami" {
  type        = string
  description = "AMI for Redpanda broker nodes (if not set, will select based on the client_distro variable"
  default     = null
}

variable "prometheus_ami" {
  type        = string
  description = "AMI for prometheus nodes (if not set, will select based on the client_distro variable"
  default     = null
}

variable "client_ami" {
  type        = string
  description = "AMI for Redpanda client nodes (if not set, will select based on the client_distro variable"
  default     = null
}

variable "public_key_path" {
  type        = string
  description = "The public key used to ssh to the hosts"
  default     = "~/.ssh/id_rsa.pub"
}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*",
      "Fedora-Cloud-Base-*.x86_64-hvm-us-west-2-gp2-0",
      "debian-*-amd64-*",
      "debian-*-hvm-x86_64-gp2-*'",
      "amzn2-ami-hvm-2.0.*-x86_64-gp2",
      "RHEL*HVM-*-x86_64*Hourly2-GP2"
    ]
  }

  filter {
    name   = "architecture"
    values = [var.machine_architecture]
  }

  filter {
    name   = "name"
    values = ["*${var.distro}*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477", "125523088429", "136693071363", "137112412989", "309956199498"]
  # Canonical, Fedora, Debian (new), Amazon, RedHat
}

variable "distro_ssh_user" {
  description = "The default user used by the AWS AMIs"
  type        = map(string)
  default = {
    "debian-10"            = "admin"
    "debian-11"            = "admin"
    "Fedora-Cloud-Base-34" = "fedora"
    "Fedora-Cloud-Base-35" = "fedora"
    #"Fedora-Cloud-Base-36" = "fedora"
    #"Fedora-Cloud-Base-37" = "fedora"
    "ubuntu-bionic"  = "ubuntu"
    "ubuntu-focal"   = "ubuntu"
    "ubuntu-hirsute" = "ubuntu"
    "ubuntu-jammy"   = "ubuntu"
    "ubuntu-kinetic" = "ubuntu"
    "RHEL-8"         = "ec2-user"
    #"RHEL-9"              = "ec2-user"
    "amzn2" = "ec2-user"
  }
}

variable "tiered_storage_enabled" {
  description = "Enables or disables tiered storage"
  type        = bool
  default     = true
}

variable "private_key_path" {
  type        = string
  description = "The contents of an SSH key to use for the connection. These can be loaded from a file on disk using the file function. This takes preference over password if provided."
  default     = "~/.ssh/id_rsa"
}

variable "security_groups_client" {
  type        = list(string)
  description = "Any additional security groups to attach to the client nodes"
  default     = []
}

variable "security_groups_prometheus" {
  type        = list(string)
  description = "Any additional security groups to attach to the prometheus nodes"
  default     = []
}

variable "security_groups_redpanda" {
  type        = list(string)
  description = "Any additional security groups to attach to the Redpanda nodes"
  default     = []
}

variable "security_groups_clickhouse" {
  type        = list(string)
  description = "Any additional security groups to attach to the ClickHouse nodes"
  default     = []
}

variable "ssh_security_rule_cidr" {
  type        = list(string)
  description = "List of CIDRs for the security group's SSH ingress rule. Defaults to 0.0.0.0/0 if not specified."
  default     = ["0.0.0.0/0"]
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet where the EC2 instances will be deployed. An empty string will deploy to the default VPC. If provided, it must be in the same VPC as vpc_id"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "A map of key value pairs passed through to AWS tags on resources"
  nullable    = true
  default     = null
}

# variable "vpc_id" {
#   type        = string
#   description = "The ID of the VPC to deploy the instances. If an ID is an empty string, the default VPC is used. If provided, the subnet_id must also be provided."
#   default     = ""
# }

variable "cloud_provider" {
  type        = string
  description = "the short, lower case form of the cloud provider"
  default     = "aws"
}

# allow_force_destroy is only intended for demos and CI testing and to support decommissioning a cluster entirely
# enabling it will result in loss of any data or topic info stored in the bucket
variable "allow_force_destroy" {
  default     = false
  type        = bool
  description = "DANGER: Enabling this option will delete your data in Tiered Storage when terraform destroy is run. Enable this only after careful consideration of the data loss consequences."
}

variable "associate_public_ip_addr" {
  default     = true
  type        = bool
  description = "Allows enabling public ips when using a custom VPC rather than the default"
}
