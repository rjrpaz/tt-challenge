terraform {
  backend "s3" {
    # Replace this with your bucket name
    bucket         = "tt-rjrpaz-tf"
    key            = "infra"
    region         = "us-east-1"
  }
}
