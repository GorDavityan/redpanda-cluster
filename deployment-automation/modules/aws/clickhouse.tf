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
    description = "Allow anywhere inbound to access HTTP API Port for http requests. used by JDBC, ODBC and web interfaces."
    from_port   = 8123
    to_port     = 8123
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 # grafana
  ingress {
    description = "Allow anywhere inbound to access "
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