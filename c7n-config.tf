locals {
  config_template_dir = "${path.module}/config/templates/"
  config_rendered_dir = "${path.module}/config/rendered/"
  config_files        = fileset(local.config_template_dir, "*.yaml")
}

resource "local_file" "build_config_files" {
  for_each = local.config_files
  content = templatefile("${local.config_template_dir}/${each.value}", {
    #sqs_queue        = module.sqs_queue.queue_id
    sqs_queue_url     = aws_sqs_queue.queue.id
    c7n_iam_role      = aws_iam_role.c7n_role.arn
    c7n_lambda_memory = var.c7n_lambda_memory_size
    tags              = jsonencode(var.tags)
  })
  filename = "${local.config_rendered_dir}/${each.value}"
}
