# --- ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = local.name
}

# --- ECR Repository for the log generator app ---
resource "aws_ecr_repository" "app" {
  name                 = "${local.name}-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "app" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    # FireLens sidecar (Fluent Bit)
    {
      name      = "fluent-bit"
      image     = "amazon/aws-for-fluent-bit:2.34.3.20260309"
      cpu       = 64
      memory    = 128
      essential = true
      user      = "0"
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          "config-file-type"        = "file"
          "config-file-value"       = "/fluent-bit/configs/parse-json.conf"
          "enable-ecs-log-metadata" = "true"
        }
      }
      environment = []
      mountPoints    = []
      portMappings   = []
      systemControls = []
      volumesFrom    = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.firelens.name
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "firelens"
        }
      }
    },
    # Application container
    {
      name           = "app"
      image          = var.app_image
      essential      = true
      environment    = []
      mountPoints    = []
      portMappings   = []
      systemControls = []
      volumesFrom    = []
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name               = "es"
          Host               = aws_opensearch_domain.logs.endpoint
          Port               = "443"
          Logstash_Format    = "On"
          Logstash_Prefix    = var.opensearch_index_prefix
          Type               = "_doc"
          AWS_Auth           = "On"
          AWS_Region         = local.region
          tls                = "On"
          Replace_Dots       = "On"
          Suppress_Type_Name = "On"
          Retry_Limit        = "5"
        }
      }
    }
  ])
}

# --- ECS Service ---
resource "aws_ecs_service" "app" {
  name            = local.name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs.id]
  }

  depends_on = [aws_route.private_nat]
}
