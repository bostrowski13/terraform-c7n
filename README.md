# terraform-c7n
Terraform to create the resources needed for running Cloud Custodian

## What Does This Module Create

This module uses Terraform to create:
  * One IAM role for the Lambdas to run under (aws_iam_role), along with the policy for that role (aws_iam_role_policy)
  * One S3 Bucket (aws_s3_bucket) per region, which custodian will write its output to
  * One SQS Queue (aws_sqs_queue) in us-east-1 for the mailer Lambda. All policies are configured to use this queue for mailer notifications, and we provision the c7n-mailer function only in us-east-1 and reading from this queue.
  * One SQS Queue (aws_sqs_queue) per region for our custom code to log to Splunk, which functions much the same as c7n-mailer.
  * A template resource to templetize all configs (for example, mailer) with appropriate values from Terraform
  * A template resource to templetize all policies and their rendered output with appropriate values from Terraform
