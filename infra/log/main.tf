# # --- log/main.tf ---

# Create a policy
resource "aws_iam_policy" "tt_cloudwatch_policy" {
  name        = "ec2_policy"
  path        = "/"
  description = "Policy to provide permission to EC2"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
    ],
      "Resource": [
        "arn:aws:logs:*:*:*"
    ]
  }
 ]
})
}

# Create a role
resource "aws_iam_role" "tt_cloudwatch_agent_role" {
  name = "tt-cloudwatch-agent-role"
  description =  "Allows EC2 instances to use CloudWatch logs"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
})
}

# Attach role to policy
resource "aws_iam_policy_attachment" "tt_ec2_policy_role" {
  name       = "tt_ec2_attachment"
  roles      = [aws_iam_role.tt_cloudwatch_agent_role.name]
  policy_arn = aws_iam_policy.tt_cloudwatch_policy.arn
}

# Attach role to an instance profile
resource "aws_iam_instance_profile" "tt_ec2_profile" {
  name = "tt_ec2_profile"
  role = aws_iam_role.tt_cloudwatch_agent_role.name
}
