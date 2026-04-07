# --- OpenSearch Service-Linked Role (required for VPC access) ---
resource "aws_iam_service_linked_role" "opensearch" {
  count            = var.create_opensearch_service_linked_role ? 1 : 0
  aws_service_name = "opensearchservice.amazonaws.com"
}

# --- OpenSearch Domain (Provisioned, single-node t3.small, VPC-based) ---

resource "aws_security_group" "opensearch" {
  name_prefix = "${local.name}-os-"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${local.name}-opensearch" }
}

resource "aws_security_group_rule" "opensearch_from_ecs" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.opensearch.id
  description              = "Allow HTTPS from ECS tasks"
}

resource "aws_opensearch_domain" "logs" {
  domain_name    = local.name
  engine_version = "OpenSearch_2.17"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  vpc_options {
    subnet_ids         = [aws_subnet.private[0].id]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 20
  }

  node_to_node_encryption {
    enabled = true
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = "es:*"
      Resource  = "arn:aws:es:${local.region}:${local.account_id}:domain/${local.name}/*"
    }]
  })

  tags = { Name = local.name }

  depends_on = [aws_iam_service_linked_role.opensearch]
}
