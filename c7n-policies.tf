locals {
  policy_template_dir = "${path.module}/policies/templates/"
  policy_rendered_dir = "${path.module}/policies/rendered/"
  policy_files        = fileset(local.policy_template_dir, "*.yaml")
}

resource "local_file" "build_policy_files" {
  for_each = local.policy_files
  content = templatefile("${local.policy_template_dir}/${each.value}", {
    slack_hook_endpoint = var.slack_webhook_endpoint
    sqs_queue           = aws_sqs_queue.queue.arn
    s3_bucket           = "s3://${aws_s3_bucket.bucket.id}/${var.c7n_reports_root_folder}/"
    account_id          = data.aws_caller_identity.current.account_id
    c7n_iam_role        = aws_iam_role.c7n_role.arn
  })
  filename = "${local.policy_rendered_dir}/${each.value}"
}
