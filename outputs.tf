output "opensearch_endpoint" {
  value = aws_opensearch_domain.logs.endpoint
}

output "opensearch_dashboard_url" {
  value = "https://${aws_opensearch_domain.logs.endpoint}/_dashboards"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "ssm_tunnel_command" {
  value = "aws ssm start-session --target ${aws_instance.bastion.id} --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters '{\"host\":[\"${aws_opensearch_domain.logs.endpoint}\"],\"portNumber\":[\"443\"],\"localPortNumber\":[\"8443\"]}' --region ${local.region}"
}
