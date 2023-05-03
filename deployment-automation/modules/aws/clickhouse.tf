# resource "random_uuid" "clickhouse_cluster" {
#   count = var.clickhouse_cluster ? 1 : 0
# }

# resource "time_static" "clickhouse_timestamp" {
#   count = var.clickhouse_cluster ? 1 : 0
# }

# locals {
#   uuid                       = length(random_uuid.clickhouse_cluster) > 0 ? random_uuid.clickhouse_cluster[0].result : 0
#   timestamp                  = length(time_static.clickhouse_timestamp) > 0 ? time_static.clickhouse_timestamp[0].unix : 0
#   deployment_id              = length(var.deployment_prefix) > 0 ? var.deployment_prefix : "clickhouse-${substr(local.uuid, 0, 8)}-${local.timestamp}"
#  # tiered_storage_bucket_name = replace("${local.deployment_id}-bucket", "_", "-")

#   # tags shared by all instances
#   instance_tags = {
#     owner : local.deployment_id
#     iam_username : trimprefix(data.aws_arn.caller_arn.resource, "user/")
#   }

#   merged_tags = merge(local.instance_tags, var.tags)
# }

# resource "aws_iam_role" "redpanda" {
#   count = var.redpanda_cluster ? 1 : 0
#   name  = local.deployment_id
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })
# }

# resource "aws_iam_instance_profile" "redpanda" {
#   count = var.redpanda_cluster ? 1 : 0
#   name  = local.deployment_id
#   role  = aws_iam_role.redpanda[count.index].name
# }


resource "aws_instance" "clickhouse" {
  count                      = var.clickhouse_cluster ? 2 : 0
  ami                        = coalesce(var.cluster_ami, data.aws_ami.ami.image_id)
  instance_type              = var.clickhouse_instance_type
  key_name                   = aws_key_pair.ssh[0].key_name
 # iam_instance_profile       = var.tiered_storage_enabled ? aws_iam_instance_profile.redpanda[0].name : null
  vpc_security_group_ids     = concat([aws_security_group.clickhouse_node_sec_group[0].id], var.security_groups_clickhouse)
  # placement_group            = var.ha ? aws_placement_group.redpanda-pg[0].id : null
  # placement_partition_number = var.ha ? (count.index % aws_placement_group.redpanda-pg[0].partition_count) + 1 : null
  availability_zone          = var.availability_zone[count.index % length(var.availability_zone)]
  subnet_id                  = module.vpc[0].public_subnets[0]
  associate_public_ip_address = var.associate_public_ip_addr
  tags = merge(
    local.merged_tags,
    {
      Name = "${local.clickhouse_deployment_id}-node-${count.index}",
    }
  )

  connection {
    user        = var.distro_ssh_user[var.distro]
    host        = self.public_ip
    private_key = file(var.private_key_path)
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_ebs_volume" "clickhouse_ebs_volume" {
  count             = var.clickhouse_cluster ? 0 : 0 * var.ec2_ebs_volume_count
  availability_zone = join(",", aws_instance.clickhouse[*].availability_zone)
  size              = var.ec2_ebs_volume_size
  type              = var.ec2_ebs_volume_type
  iops              = var.ec2_ebs_volume_iops
  throughput        = var.ec2_ebs_volume_throughput
}

resource "aws_volume_attachment" "clickhouse_volume_attachment" {
  count       = var.clickhouse_cluster ? 0 : 0 * var.ec2_ebs_volume_count
  volume_id   = join(",", aws_ebs_volume.clickhouse_ebs_volume[*].id)
  device_name = var.ec2_ebs_device_names[count.index]
  instance_id = join(",", aws_instance.clickhouse[*].id)
}

# resource "aws_instance" "prometheus" {
#   count                  = var.enable_monitoring ? 1 : 0
#   ami                    = coalesce(var.prometheus_ami, data.aws_ami.ami.image_id)
#   instance_type          = var.prometheus_instance_type
#   key_name               = aws_key_pair.ssh[0].key_name
#   subnet_id              = module.vpc[0].public_subnets[0]
#   vpc_security_group_ids = concat([aws_security_group.node_sec_group[0].id], var.security_groups_prometheus)
#   associate_public_ip_address = var.associate_public_ip_addr
#   tags = merge(
#     local.merged_tags,
#     {
#       Name = "${local.deployment_id}-prometheus",
#     }
#   )

#   connection {
#     user        = var.distro_ssh_user[var.distro]
#     host        = self.public_ip
#     private_key = file(var.private_key_path)
#   }

#   lifecycle {
#     ignore_changes = [ami]
#   }
# }

resource "aws_security_group" "clickhouse_node_sec_group" {
  count       = var.clickhouse_cluster ? 1 : 0
  name        = "${local.clickhouse_deployment_id}-node-sec-group"
  tags        = local.merged_tags
  description = "clickhouse ports"
  vpc_id      = module.vpc[0].vpc_id

  # SSH access from anywhere
  ingress {
    description = "Allow inbound to ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_security_rule_cidr
  }

 # grafana
  ingress {
    description = "Allow anywhere inbound to access grafana end point for monitoring"
    from_port   = 8123
    to_port     = 8123
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 # grafana
  ingress {
    description = "Allow anywhere inbound to access grafana end point for monitoring"
    from_port   = 9500
    to_port     = 9500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # grafana
  ingress {
    description = "Allow anywhere inbound to access grafana end point for monitoring"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # prometheus
  ingress {
    description = "Allow anywhere inbound to access Prometheus end point for monitoring"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # node exporter
  ingress {
    description = "node_exporter access within the security-group for ansible"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    self        = true
  }

  # outbound internet access
  egress {
    description = "Allow all outbound Internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_key_pair" "ssh" {
#   count      = var.clickhouse_cluster ? 1 : 0
#   key_name   = "${local.deployment_id}-key"
#   public_key = file(var.public_key_path)
#   tags       = local.merged_tags
# }

# resource "local_file" "clickhouse_hosts_ini_for_ci" {
#   count = var.clickhouse_cluster ? 1 : 0
#   content = templatefile("${path.module}/../../templates/hosts_ini.tpl",
#     {
#       cloud_storage_region       = var.aws_region
#      # client_public_ips          = aws_instance.client[*].public_ip
#      # client_private_ips         = aws_instance.client[*].private_ip
#      # enable_monitoring          = var.enable_monitoring
#      # monitor_public_ip          = var.enable_monitoring ? aws_instance.prometheus[0].public_ip : ""
#      # monitor_private_ip         = var.enable_monitoring ? aws_instance.prometheus[0].private_ip : ""
#      # rack                       = var.ha ? aws_instance.redpanda[*].placement_partition_number : aws_instance.redpanda[*].availability_zone
#      # rack_awareness             = var.ha || length(var.availability_zone) > 1
#       availability_zone          = aws_instance.clickhouse[*].availability_zone
#       clickhouse_public_ips        = aws_instance.clickhouse[*].public_ip
#       clickhouse_private_ips       = aws_instance.clickhouse[*].private_ip
#       ssh_user                   = var.distro_ssh_user[var.distro]
#       #tiered_storage_bucket_name = local.tiered_storage_bucket_name
#       #tiered_storage_enabled     = var.tiered_storage_enabled
#     }
#   )
#   filename = "${path.module}/../../artifacts/hosts_${var.cloud_provider}_${var.deployment_prefix}.ini"
# }

# ## TODO remove this and update docs accordingly
# resource "local_file" "clickhouse_hosts_ini" {
#   count = var.clickhouse_cluster ? 1 : 0
#   content = templatefile("${path.module}/../../templates/hosts_ini.tpl",
#     {
#       cloud_storage_region       = var.aws_region
#      # client_public_ips          = aws_instance.client[*].public_ip
#      # client_private_ips         = aws_instance.client[*].private_ip
#       #enable_monitoring          = var.enable_monitoring
#      # monitor_public_ip          = var.enable_monitoring ? aws_instance.prometheus[0].public_ip : ""
#      # monitor_private_ip         = var.enable_monitoring ? aws_instance.prometheus[0].private_ip : ""
#      # rack                       = var.ha ? aws_instance.redpanda[*].placement_partition_number : aws_instance.redpanda[*].availability_zone
#      # rack_awareness             = var.ha || length(var.availability_zone) > 1
#       availability_zone          = aws_instance.clickhouse[*].availability_zone
#       clickhouse_public_ips        = aws_instance.clickhouse[*].public_ip
#       clickhouse_private_ips       = aws_instance.clickhouse[*].private_ip
#       ssh_user                   = var.distro_ssh_user[var.distro]
#       #tiered_storage_bucket_name = local.tiered_storage_bucket_name
#       #tiered_storage_enabled     = var.tiered_storage_enabled
#     }
#   )
#   filename = "${path.module}/../../hosts.ini"
# }

# locals {
#   node_details = [
#     for index, instance in aws_instance.clickhouse :
#     {
#       "instance_id" : instance.id
#       "public_ip" : instance.public_ip
#       "private_ip" : instance.private_ip
#       "name" : "${var.deployment_prefix}-node-${index}"
#     }
#   ]
# }

# we extract the IAM username by getting the caller identity as an ARN
# then extracting the resource protion, which gives something like 
# user/travis.downs, and finally we strip the user/ part to use as a tag
# data "aws_caller_identity" "current" {}

# data "aws_arn" "caller_arn" {
#   arn = data.aws_caller_identity.current.arn
# }