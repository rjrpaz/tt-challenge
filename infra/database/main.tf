# --- database/main.tf ---

resource "aws_db_instance" "tt_db" {
  allocated_storage      = var.db_storage
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.dbname
  username               = var.dbuser
  password               = var.dbpassword
  db_subnet_group_name   = var.db_subnet_group_name[0]
  vpc_security_group_ids = [var.vpc_security_group_ids]
  identifier             = var.db_identifier
  skip_final_snapshot    = var.skip_db_snapshot
  apply_immediately      = true
  snapshot_identifier    = "tt-db-snapshot"
  # backup_window           = "00:00-03:00"
  backup_retention_period = 1
  multi_az                = false

  tags = {
    name = "tt-db"
  }

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

resource "aws_db_instance" "tt_db_replica" {
  count               = var.create_replica ? 1 : 0
  allocated_storage   = var.db_storage
  replicate_source_db = aws_db_instance.tt_db.id
  instance_class      = var.db_instance_class
  snapshot_identifier = "tt-db-replica-snapshot"
  tags = {
    name = "tt-db-replica"
  }
}

# Adding backup

# Create s3 bucket to store lambda layer
resource "aws_s3_bucket" "s3_for_lambda_layer" {
  bucket = "tt-lambda-layer-bucket"

  tags = {
    Name = "s3 lambda layer bucket"
  }
}

resource "aws_s3_bucket_acl" "s3_for_lambda_layer_acl" {
  bucket = aws_s3_bucket.s3_for_lambda_layer.id
  acl    = "private"
}

# Create lambda layer to store required python libraries
module "lambda_layer_s3" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "tt-lambda-layer-s3"
  description         = "TT lambda layer (deployed from S3)"
  compatible_runtimes = ["python3.9"]

  source_path = "../backup_rds/packages/lambda-python-libs.zip"

  store_on_s3 = true
  s3_bucket   = aws_s3_bucket.s3_for_lambda_layer.id
}

# Create lambda function to take a snapshot of the RDS
module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "backup-rds"
  description   = "Take rds snapshot"
  handler       = "backup_rds.lambda_handler"
  runtime       = "python3.9"
  publish       = true

  attach_policy_json = true
  policy_json        = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Sid": "AllowToTakeSnapshot",
     "Action": [
       "rds:DescribeDBInstances",
       "rds:CreateDBSnapshot"
     ],
     "Resource": "*",
     "Effect": "Allow"
   }
 ]
}
EOF  

  source_path = "../backup_rds/backup_rds.py"

  store_on_s3 = true
  s3_bucket   = "tt-rjrpaz-lambda-layer"

  layers = [
    module.lambda_layer_s3.lambda_layer_arn,
  ]

  environment_variables = {
    Serverless = "Terraform"
  }

  tags = {
    Module = "lambda-with-layer"
  }
}

# Configure cloudwatch to run the backup once a day, at 21
resource "aws_cloudwatch_event_rule" "rds_daily_backup" {
  name                = "tt-rds-daily-backup"
  description         = "Run RDS backup once a day"
  schedule_expression = "cron(20 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "run_rds_backup" {
  rule      = aws_cloudwatch_event_rule.rds_daily_backup.name
  target_id = "lambda"
  arn       = module.lambda_function.lambda_function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_daily_backup.arn
}