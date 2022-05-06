# Delivery for a three-tier Node application in the cloud

You want to design a continuous delivery architecture for a scalable and secure 3 tier Node application.

Application to use can be found on [https://git.toptal.com/rjrpaz/node-3tier-app2](https://git.toptal.com/rjrpaz/node-3tier-app2).

## Requirements

The requirements for the test project are:

- Both web and API tiers should be exposed to the internet and DB tier should not be accessible from the internet.

- You should clone the repository and use it as the base for your system.

- You need to create resources for all the tiers.

- The architecture should be completely provisioned via some infrastructure as a code tool.

- Presented solution must handle server (instance) failures.

- Components must be updated without downtime in service.

- The deployment of new code should be completely automated (bonus points if you create tests and include them into the pipeline).

- The database and any mutable storage need to be backed up at least daily.

- All relevant logs for all tiers need to be easily accessible (having them on the hosts is not an option).

- You should clone the repository and use it as the base for your system.

- You should be able to deploy it on one larger Cloud provider: AWS / Google Cloud / Azure / DigitalOcean / RackSpace.

- The system should present relevant historical metrics to spot and debug bottlenecks.

- The system should implement CDN to allow content distribution based on client location

As a solution, please commit to the Toptal git repo the following:

- An architectural diagram / PPT to explain your architecture during the interview.

- All the relevant configuration scripts (Terraform/Ansible/Cloud Formation/ARM Templates)

- All the relevant runtime handling scripts (start/stop/scale nodes).

- All the relevant backup scripts.

- You can use another git provider to leverage hooks, CI/CD or other features not enabled in Toptal’s git. Everything else, including the code for the CI/CD pipeline, must be pushed to Toptal’s git.

## Infrastructure for the app

I'm going to use *AWS* as cloud provider. AWS region to be used is *us-east-1*.

I'm going to use *terraform* to create the infrastructure for the app. In case you need to install terraform, you can check [here](https://learn.hashicorp.com/tutorials/terraform/install-cli).

Main steps are:

1. Create AWS credentials
2. Create S3 bucket to store terraform state
3. Create infrastructure using terraform

### Create AWS credentials

You should request API credentials for an IAM user with enough privileges to do required actions in AWS:

- create/destroy EC2 instances
- read/write access to the S3 bucket
- create/destroy networking objects (VPC, routes)
- create/destroy load balancers

Check [here](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/getting-your-credentials.html) about how to create the credentials.

### Create S3 bucket to store terraform state

Terraform state is stored in an s3 bucket. You can create this bucket using AWS credentials and *aws cli* tool.

In case you need to install *aws cli*, you can check [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

Export AWS credentials to be used by the cli and by terraform:

```bash
export AWS_ACCESS_KEY_ID="<replace_with_key_value>"
export AWS_SECRET_ACCESS_KEY="<replace_with_secret_value>"
```

I will save the terraform state in a bucket named *tt-rjrpaz-tf*. Choose a proper name yourself and create the bucket:

```bash
aws s3api create-bucket --bucket tt-rjrpaz-tf --region us-east-1
```

the command will return something like this:

```bash
{
    "Location": "/tt-rjrpaz-tf"
}
```

### Create infrastructure using terraform

Change to directory [infra]([./infra]):

```bash
cd infra
```

Update file *backends.tf* and define the name of the s3 bucket created in previous step. It should look like this:

```console
$ cat backends.tf
terraform {
  backend "s3" {
    # Replace this with your bucket name
    bucket         = "tt-rjrpaz-tf"
    key            = "infra"
    region         = "us-east-1"
  }
}
```

Initialize terraform:

```bash
terraform init
```

Check modifications to be done before apply them:

```bash
terraform plan
```




<!-- The requirements for the test project are:

- Both web and API tiers should be exposed to the internet and DB tier should not be accessible from the internet.

- You should clone the repository and use it as the base for your system.

- You need to create resources for all the tiers.

- The architecture should be completely provisioned via some infrastructure as a code tool.

- Presented solution must handle server (instance) failures.

- Components must be updated without downtime in service.

- The deployment of new code should be completely automated (bonus points if you create tests and include them into the pipeline).

- The database and any mutable storage need to be backed up at least daily.

- All relevant logs for all tiers need to be easily accessible (having them on the hosts is not an option).

- You should clone the repository and use it as the base for your system.

- You should be able to deploy it on one larger Cloud provider: AWS / Google Cloud / Azure / DigitalOcean / RackSpace.

- The system should present relevant historical metrics to spot and debug bottlenecks.

- The system should implement CDN to allow content distribution based on client location

As a solution, please commit to the Toptal git repo the following:

- An architectural diagram / PPT to explain your architecture during the interview.

- All the relevant configuration scripts (Terraform/Ansible/Cloud Formation/ARM Templates)

- All the relevant runtime handling scripts (start/stop/scale nodes).

- All the relevant backup scripts.

- You can use another git provider to leverage hooks, CI/CD or other features not enabled in Toptal’s git. Everything else, including the code for the CI/CD pipeline, must be pushed to Toptal’s git. -->
