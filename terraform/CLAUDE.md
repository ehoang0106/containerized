# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform infrastructure-as-code repository that provisions an AWS infrastructure for the "Orbwatch" application. The infrastructure is split into two separate Terraform configurations with independent state files, following a layered architecture pattern.

## Architecture

### Two-Layer Infrastructure Pattern

The infrastructure is divided into two directories, each with its own Terraform state:

1. **network/** - Foundation networking layer
   - State: `terraform-state-orbwatch-database` in S3
   - Creates: VPC, subnets, internet gateway, route tables, security groups
   - Must be deployed first as other resources depend on it

2. **infra/** - Application infrastructure layer
   - State: `terraform-state-orbwatch-infra` in S3
   - Creates: RDS MySQL database, ECS cluster/service, ALB, Auto Scaling Group, Route53 DNS
   - Uses `data` sources to reference resources from the network layer

### Resource Dependencies

The infra layer uses data sources to reference network layer resources by tag names:
- VPC: `orbwatch-vpc`
- Subnets: `orbwatch-subnet1`, `orbwatch-subnet2`
- Security Groups: `orbwatch-sg`, `db-sg`

The ECS task definition references a container image at `706572850235.dkr.ecr.us-west-1.amazonaws.com/orbwatch:latest` and passes database connection details as environment variables.

## Common Commands

### Deployment Order

Deploy the networking layer first, then the infrastructure layer:

```bash
# Deploy networking resources
cd network
terraform init
terraform plan
terraform apply

# Deploy infrastructure resources
cd ../infra
terraform init
terraform plan -var="db_username=<username>" -var="db_password=<password>"
terraform apply -var="db_username=<username>" -var="db_password=<password>"
```

### Required Variables

The infra layer requires sensitive variables to be passed:
- `db_username` - RDS database username (sensitive)
- `db_password` - RDS database password (sensitive)

These should be passed via command line, environment variables, or a `.tfvars` file (not committed to git).

### Standard Operations

```bash
# Initialize Terraform (run in network/ or infra/)
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources (reverse order: infra first, then network)
cd infra
terraform destroy
cd ../network
terraform destroy

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate
```

## Key Infrastructure Details

### ECS Cluster Configuration

- Cluster uses EC2 launch type (not Fargate)
- Launch template AMI: `ami-01eb4eefd88522422` (ECS-optimized Amazon Linux 2)
- Instance type: `t3.medium`
- User data script in `infra/userdata.tftpl` configures ECS agent
- Capacity provider manages ASG scaling

### Database Configuration

- Engine: MySQL 8.0.40
- Instance class: `db.t3.micro`
- Publicly accessible (consider security implications)
- Skip final snapshot enabled (not recommended for production)

### Load Balancer Setup

- Application Load Balancer with HTTP (port 80) and HTTPS (port 443) listeners
- HTTPS certificate ARN is hardcoded in variables
- Routes to Route53 domain: `orbwatch.khoah.net`

### Security Groups

- `orbwatch-sg`: Allows SSH (22), HTTP (80), HTTPS (443) from 0.0.0.0/0
- `db-sg`: Allows MySQL (3306) from 0.0.0.0/0 (overly permissive, review for production)

## Important Notes

- All resources are in `us-west-1` region
- S3 backend bucket: `terraform-state-khoa-hoang`
- The two-layer architecture requires careful coordination when making changes that affect both layers
- When modifying network resources, verify that infra data sources still resolve correctly
- CloudWatch logs retention is set to 1 day for cost optimization
