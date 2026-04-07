# --- Bastion for SSM port forwarding to OpenSearch Dashboards ---

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_iam_role" "bastion" {
  name = "${local.name}-bastion"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_security_group" "bastion" {
  name_prefix = "${local.name}-bastion-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = { Name = "${local.name}-bastion" }
}

# Allow bastion to reach OpenSearch
resource "aws_security_group_rule" "opensearch_from_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.opensearch.id
  description              = "Allow HTTPS from bastion"
}

resource "aws_instance" "bastion" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = "t4g.nano"
  subnet_id            = aws_subnet.private[0].id
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = { Name = "${local.name}-bastion" }
}
