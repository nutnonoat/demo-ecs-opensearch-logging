# --- ECS Managed Instances Capacity Provider ---

# Infrastructure role for ECS to manage EC2 instances
resource "aws_iam_role" "ecs_infrastructure" {
  name = "${local.name}-ecs-infrastructure"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAccessToECSForInfrastructureManagement"
      Effect    = "Allow"
      Principal = { Service = "ecs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_infrastructure_managed_instances" {
  role       = aws_iam_role.ecs_infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForManagedInstances"
}

resource "aws_iam_role_policy" "ecs_infrastructure_pass_role" {
  name = "pass-role"
  role = aws_iam_role.ecs_infrastructure.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "iam:PassRole"
      Resource = aws_iam_role.ecs_managed_instance.arn
    }]
  })
}

# Instance profile for the managed EC2 instances
resource "aws_iam_role" "ecs_managed_instance" {
  name = "${local.name}-ecs-managed-instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_managed_instance_ec2" {
  role       = aws_iam_role.ecs_managed_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_managed_instance_ssm" {
  role       = aws_iam_role.ecs_managed_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_managed_instance" {
  name = "${local.name}-ecs-managed-instance"
  role = aws_iam_role.ecs_managed_instance.name
}

# Managed Instances capacity provider
resource "aws_ecs_capacity_provider" "managed_instances" {
  name    = "${local.name}-mi"
  cluster = aws_ecs_cluster.main.name

  depends_on = [aws_iam_role_policy_attachment.ecs_infrastructure_managed_instances]

  managed_instances_provider {
    infrastructure_role_arn = aws_iam_role.ecs_infrastructure.arn
    propagate_tags          = "CAPACITY_PROVIDER"

    instance_launch_template {
      ec2_instance_profile_arn = aws_iam_instance_profile.ecs_managed_instance.arn

      network_configuration {
        subnets         = aws_subnet.private[*].id
        security_groups = [aws_security_group.ecs.id]
      }

      storage_configuration {
        storage_size_gib = 30
      }

      instance_requirements {
        memory_mib {
          min = 2048
          max = 4096
        }
        vcpu_count {
          min = 1
          max = 2
        }
        instance_generations = ["current"]
        cpu_manufacturers    = ["amazon-web-services"]
      }
    }
  }
}

# Register both Fargate and Managed Instances on the cluster
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", aws_ecs_capacity_provider.managed_instances.name]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# --- ECS Service on Managed Instances ---
resource "aws_ecs_service" "app_mi" {
  name            = "${local.name}-mi"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.managed_instances.name
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs.id]
  }
}
