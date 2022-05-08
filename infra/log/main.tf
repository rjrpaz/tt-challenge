# --- log/main.tf ---

#Create a policy
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2_policy"
  path        = "/"
  description = "Policy to provide permission to EC2"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = "arn:aws:ssm:us-east-2:${local.account_id}:parameter/dev*"
      },
      {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:List*"
        ],
        "Resource": [
            "arn:aws:s3:::skundu-proj3-3p-installers/download/*"
        ]
      }
    ]
  })
}

#Create a role
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

#Attach role to policy
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment
resource "aws_iam_policy_attachment" "ec2_policy_role" {
  name       = "ec2_attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.ec2_policy.arn
}

#Attach role to an instance profile
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}


# resource "aws_iam_role" "tt_log_role" {
#   name                = "tt-log"

#   assume_role_policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Action": [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "logs:DescribeLogStreams"
#       ],
#         "Resource": [
#           "*"
#       ]
#     }
#   ]
# })

#   tags = {
#     name = "tt-log"
#   }
# }

# resource "aws_lb" "tt_lb" {
#   name            = var.lb_name
#   subnets         = var.public_subnets
#   security_groups = [var.public_sg]
#   idle_timeout    = 400
# }

# resource "aws_lb_target_group" "tt_tg" {
#   name     = "tt-lb-tg-${substr(uuid(), 0, 3)}"
#   port     = var.tg_port     # 80
#   protocol = var.tg_protocol # HTTP
#   vpc_id   = var.vpc_id
#   lifecycle {
#     ignore_changes        = [name]
#     create_before_destroy = true
#   }
#   health_check {
#     healthy_threshold   = var.lb_healthy_threshold   # 2
#     unhealthy_threshold = var.lb_unhealthy_threshold # 2
#     timeout             = var.lb_timeout             # 3
#     interval            = var.lb_interval            # 30
#   }
# }

# resource "aws_lb_listener" "tt_lb_listener" {
#   load_balancer_arn = aws_lb.tt_lb.arn
#   port              = var.listener_port     # 80
#   protocol          = var.listener_protocol # "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tt_tg.arn
#   }
# }
