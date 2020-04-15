
output "c7n_role_id" {
  value = aws_iam_role.c7n_role.id
}

output "c7n_role_arn" {
  value = aws_iam_role.c7n_role.arn
}

output "bucket_id" {
  value = "s3://${aws_s3_bucket.bucket.id}"
}

output "sqs_url" {
  value = aws_sqs_queue.queue.id
}

output "custodian_log_group" {
  value = var.c7n_cw_log_group
}
