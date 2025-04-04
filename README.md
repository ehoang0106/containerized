# Containerized My Python Flask Web App with AWS ECS, RDS, and Terraform

This project demonstrates a containerized Python Flask web application deployed on AWS ECS (Elastic Container Service) with RDS (Relational Database Service) as the backend database, all managed through Terraform infrastructure as code.

## Architecture Overview

- **Frontend**: Python Flask web application
- **Container**: Docker container running on AWS ECS
- **Database**: AWS RDS (MySQL/MariaDB)
- **Infrastructure**: Managed through Terraform
- **CI/CD**: GitHub Actions for automated deployment

## Prerequisites

- AWS Account with appropriate permissions
- Terraform installed locally
- Docker installed locally
- AWS CLI configured
- Python 3.x
- pip package manager


## Local Development Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-name>
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

5. Run the application locally:
```bash
python myapp/app.py
```

## Docker Setup

1. Build the Docker image:
```bash
docker build -t orbwatch .
```

2. Run the container locally:
```bash
docker run -p 80:80 orbwatch
```

## Infrastructure Deployment

The infrastructure is split into two parts: network and application infrastructure. Each has its own Terraform configuration.

### Network Infrastructure

1. Navigate to the network directory:
```bash
cd terraform/network
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review the planned changes:
```bash
terraform plan
```

4. Apply the network infrastructure:
```bash
terraform apply
```

### Application Infrastructure

1. Navigate to the infrastructure directory:
```bash
cd terraform/infra
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review the planned changes:
```bash
terraform plan
```

4. Apply the application infrastructure:
```bash
terraform apply
```

Note: The network infrastructure must be deployed before the application infrastructure, as the application infrastructure depends on the network resources.

## Environment Variables

Required environment variables:
- `DB_HOST`: RDS endpoint
- `DB_USER`: Database username
- `DB_PASSWORD`: Database password
- `DB_NAME`: Database name
