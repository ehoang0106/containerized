# Infrastructure Architecture Explanation

## Overview

This infrastructure deploys a containerized application ("Orbwatch") using AWS ECS in **EC2 mode** (not Fargate) with an Application Load Balancer, Auto Scaling, and an RDS MySQL database.

## Architecture Diagram Flow

```
Internet
    |
    v
Route53 DNS (orbwatch.khoah.net)
    |
    v
Application Load Balancer (HTTP/HTTPS)
    |
    v
Target Group (port 80)
    |
    v
Auto Scaling Group (EC2 Instances)
    |
    v
ECS Container Instances (running Docker)
    |
    v
ECS Tasks (your application containers)
    |
    v
RDS MySQL Database
```

## Key Components and Relationships

### 1. ECS Cluster (EC2 Mode)

Your setup uses **ECS EC2 launch type**, not Fargate. Here's what that means:

- **ECS Cluster**: A logical grouping named "orbwatch-cluster"
- **EC2 Instances**: You manage the underlying EC2 instances (via Auto Scaling Group)
- **Container Instances**: EC2 instances that register themselves with the ECS cluster
- **ECS Tasks**: Docker containers that run on your EC2 instances

### 2. Auto Scaling Group + ECS Integration

This is the critical relationship you asked about:

**Auto Scaling Group's Role:**
- Provisions and manages EC2 instances (t3.medium)
- Uses a Launch Template that defines instance configuration
- Maintains 1 instance (min: 1, max: 1, desired: 1)

**Launch Template Configuration:**
- AMI: `ami-01eb4eefd88522422` (Amazon ECS-optimized Linux 2)
- Instance type: `t3.medium`
- IAM role: `ecsInstanceRole` (allows instance to register with ECS)
- User data script (`userdata.tftpl`):
  ```bash
  #!/bin/bash
  sudo yum install -y ecs-init
  sudo echo ECS_CLUSTER="orbwatch-cluster" | sudo tee /etc/ecs/ecs.config
  sudo systemctl start docker
  sudo systemctl enable --now --no-block ecs.service
  ```

**What the User Data Does:**
1. Installs ECS agent
2. Configures the instance to join "orbwatch-cluster"
3. Starts Docker daemon
4. Starts ECS service

**When an EC2 instance launches:**
1. ASG creates the instance from the launch template
2. User data script runs automatically
3. ECS agent registers the instance with the ECS cluster
4. Instance becomes available as a "container instance"
5. ECS can now schedule tasks on this instance

### 3. ECS Capacity Provider

The **Capacity Provider** is the bridge between ASG and ECS:

```hcl
aws_ecs_capacity_provider.orbwatch_capacity_provider
  └─ Links to: aws_autoscaling_group.orbwatch_asg
  └─ Enables: Managed scaling
  └─ Target capacity: 100%
```

**What it does:**
- Tells ECS: "Use this Auto Scaling Group to provide compute capacity"
- Enables ECS to automatically scale the ASG based on task demand
- In your setup: Min 1 step, Max 1000 steps, target 100% capacity utilization

### 4. ECS Service

The **ECS Service** manages your running containers:

- **Task Definition**: Defines your container (image, CPU, memory, env vars)
- **Desired Count**: 1 task running
- **Capacity Provider Strategy**: Use the capacity provider with weight 100
- **Load Balancer Integration**: Registers container port 80 with target group

**How it works:**
1. ECS Service says "I need 1 task running"
2. ECS scheduler finds available container instance (EC2 from ASG)
3. ECS starts the Docker container on that instance
4. Container binds to host port 80
5. ECS registers the EC2 instance with the ALB target group
6. ALB can now route traffic to the container

### 5. Application Load Balancer Integration

**Load Balancer Setup:**
- **Target Group**: Targets EC2 instances (not IP mode) on port 80
- **ALB**: Routes traffic from internet to target group
- **Listeners**:
  - HTTP (port 80) → forwards to target group
  - HTTPS (port 443) → forwards to target group (with SSL cert)

**How traffic flows:**
1. User requests `https://orbwatch.khoah.net`
2. Route53 resolves to ALB DNS name
3. ALB listener (443) receives request
4. ALB forwards to target group
5. Target group routes to EC2 instance on port 80
6. Docker container receives request on port 80
7. Application processes request

**Network Mode: Bridge**
- Task definition uses `network_mode = "bridge"`
- Container port 80 maps to host port 80
- This is why target group targets instances, not IPs

### 6. ECS Task Definition Details

```json
Container Definition:
- Image: 706572850235.dkr.ecr.us-west-1.amazonaws.com/orbwatch:latest
- CPU: 1024 units (1 vCPU)
- Memory: 2048 MB
- Port: Container 80 → Host 80
- Environment Variables:
  - DB_HOST: RDS endpoint
  - DB_USERNAME: from variable
  - DB_PASSWORD: from variable
```

### 7. Container Image (ECR)

Your container image is stored in **Amazon ECR** (Elastic Container Registry):
- Repository: `orbwatch`
- Tag: `latest`
- Account: `706572850235`
- Region: `us-west-1`

**How ECS pulls the image:**
1. Task definition references ECR image URI
2. ECS agent on EC2 instance uses IAM role to authenticate
3. ECS agent pulls image from ECR
4. Docker starts container from the pulled image

### 8. Database Connection

- **RDS MySQL 8.0.40** running on `db.t3.micro`
- Publicly accessible (for external connections if needed)
- Connection details passed to ECS task via environment variables
- ECS containers connect to RDS using the endpoint

## Complete Dependency Chain

```
VPC
 ├─ Subnets (2 AZs)
 ├─ Internet Gateway
 ├─ Route Table
 └─ Security Groups
      ├─ orbwatch-sg (EC2 instances & ALB)
      └─ db-sg (RDS database)

RDS Database
 └─ Depends on: VPC, Subnets, Security Group

ECS Cluster (logical grouping)

Launch Template
 └─ Depends on: IAM Role, ECS Cluster (name in user data)

Auto Scaling Group
 └─ Depends on: Launch Template, Subnets

ECS Capacity Provider
 └─ Depends on: Auto Scaling Group

Target Group
 └─ Depends on: VPC

Application Load Balancer
 └─ Depends on: Subnets, Security Group

ALB Listeners
 └─ Depends on: ALB, Target Group

ECS Task Definition
 └─ Depends on: ECR Image, IAM Roles, RDS endpoint

ECS Cluster Capacity Providers
 └─ Depends on: ECS Cluster, Capacity Provider

ECS Service
 └─ Depends on: ECS Cluster, Task Definition, Target Group,
               Capacity Provider, ASG (running instances)

Route53 Record
 └─ Depends on: ALB
```

---

## Manual Setup Order (AWS Console)

If you want to recreate this infrastructure manually via AWS Console, follow this exact order:

### Phase 1: Foundation (Networking & IAM)

1. **Create VPC**
   - Navigate to: VPC → Create VPC
   - CIDR: `10.0.0.0/16`
   - Enable DNS support and DNS hostnames
   - Tag: `Name = orbwatch-vpc`

2. **Create Subnets** (2 subnets in different AZs)
   - Navigate to: VPC → Subnets → Create subnet
   - Subnet 1: `10.0.0.0/24` in `us-west-1a` (Tag: orbwatch-subnet1)
   - Subnet 2: `10.0.1.0/24` in `us-west-1c` (Tag: orbwatch-subnet2)

3. **Create Internet Gateway**
   - Navigate to: VPC → Internet Gateways → Create
   - Attach to orbwatch-vpc
   - Tag: `Name = orbwatch-igw`

4. **Create Route Table**
   - Navigate to: VPC → Route Tables → Create
   - Add route: `0.0.0.0/0` → Internet Gateway
   - Associate with both subnets
   - Tag: `Name = orbwatch-route-table`

5. **Create Security Groups**
   - Navigate to: EC2 → Security Groups → Create

   **Security Group 1: orbwatch-sg**
   - VPC: orbwatch-vpc
   - Inbound:
     - SSH (22) from 0.0.0.0/0
     - HTTP (80) from 0.0.0.0/0
     - HTTPS (443) from 0.0.0.0/0
   - Outbound: All traffic
   - Tag: `Name = orbwatch-sg`

   **Security Group 2: db-sg**
   - VPC: orbwatch-vpc
   - Inbound: MySQL (3306) from 0.0.0.0/0
   - Outbound: All traffic
   - Tag: `Name = db-sg`

6. **Verify IAM Roles Exist**
   - Navigate to: IAM → Roles
   - Check for: `ecsInstanceRole` (for EC2 instances)
   - Check for: `ecsTaskExecutionRole` (for ECS tasks)
   - If missing, create them with appropriate policies

### Phase 2: Container Registry & Database

7. **Create ECR Repository**
   - Navigate to: ECR → Repositories → Create repository
   - Name: `orbwatch`
   - Tag immutability: Disabled
   - Scan on push: Optional

8. **Push Docker Image to ECR**
   - Authenticate Docker to ECR:
     ```bash
     aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 706572850235.dkr.ecr.us-west-1.amazonaws.com
     ```
   - Tag your image:
     ```bash
     docker tag your-image:tag 706572850235.dkr.ecr.us-west-1.amazonaws.com/orbwatch:latest
     ```
   - Push image:
     ```bash
     docker push 706572850235.dkr.ecr.us-west-1.amazonaws.com/orbwatch:latest
     ```

9. **Create RDS Database**
   - Navigate to: RDS → Databases → Create database
   - Engine: MySQL 8.0.40
   - Template: Free tier or Dev/Test
   - DB instance identifier: `orbwatch-db`
   - Master username: (set your username)
   - Master password: (set your password)
   - Instance class: `db.t3.micro`
   - Storage: 20 GB
   - VPC: orbwatch-vpc
   - Subnet group: Create new with both subnets
   - Public access: Yes
   - VPC security group: db-sg
   - Database name: `mydb`
   - Disable automated backups (for testing)
   - Tag: `Name = orbwatch-db`
   - **Note the endpoint after creation**

### Phase 3: Load Balancer & Target Group

10. **Create Target Group**
    - Navigate to: EC2 → Target Groups → Create target group
    - Target type: Instances
    - Name: `orbwatch-target-group`
    - Protocol: HTTP, Port: 80
    - VPC: orbwatch-vpc
    - Health check path: `/`
    - Health check timeout: 30s
    - Health check interval: 35s
    - Healthy threshold: 2
    - Unhealthy threshold: 3
    - Don't register targets yet (ECS will do this)

11. **Create Application Load Balancer**
    - Navigate to: EC2 → Load Balancers → Create Load Balancer
    - Type: Application Load Balancer
    - Name: `orbwatch-alb`
    - Scheme: Internet-facing
    - IP address type: IPv4
    - VPC: orbwatch-vpc
    - Subnets: Select both orbwatch-subnet1 and orbwatch-subnet2
    - Security group: orbwatch-sg
    - **Note the DNS name after creation**

12. **Create ALB Listeners**
    - Navigate to: ALB → Listeners tab

    **HTTP Listener:**
    - Port: 80
    - Default action: Forward to orbwatch-target-group

    **HTTPS Listener:**
    - Port: 443
    - Default action: Forward to orbwatch-target-group
    - SSL certificate: Select your ACM certificate

### Phase 4: ECS Cluster Setup

13. **Create ECS Cluster**
    - Navigate to: ECS → Clusters → Create Cluster
    - Cluster name: `orbwatch-cluster`
    - Infrastructure: Amazon EC2 instances (NOT Fargate)
    - Don't configure auto scaling here yet

14. **Create CloudWatch Log Group**
    - Navigate to: CloudWatch → Log groups → Create log group
    - Name: `/ecs/orbwatch-task-definition`
    - Retention: 1 day

15. **Create ECS Task Definition**
    - Navigate to: ECS → Task Definitions → Create new Task Definition
    - Family name: `orbwatch-task-definition`
    - Launch type: EC2
    - Network mode: Bridge
    - Task role: ecsTaskExecutionRole
    - Task execution role: ecsTaskExecutionRole
    - Task size:
      - CPU: 1024 (1 vCPU)
      - Memory: 2048 MB

    **Container definition:**
    - Name: `orbwatch`
    - Image URI: `706572850235.dkr.ecr.us-west-1.amazonaws.com/orbwatch:latest`
    - Memory: 2048 MB (hard limit)
    - Port mappings:
      - Container port: 80
      - Host port: 80
      - Protocol: tcp
    - Environment variables:
      - `DB_HOST` = (your RDS endpoint without port)
      - `DB_USERNAME` = (your database username)
      - `DB_PASSWORD` = (your database password)
    - Log configuration:
      - Log driver: awslogs
      - awslogs-group: `/ecs/orbwatch-task-definition`
      - awslogs-region: `us-west-1`
      - awslogs-stream-prefix: `ecs`

### Phase 5: Auto Scaling & Capacity Provider

16. **Create Launch Template**
    - Navigate to: EC2 → Launch Templates → Create launch template
    - Name: `orbwatch-launch-template`
    - AMI: Search for "Amazon ECS-optimized AMI" or use `ami-01eb4eefd88522422`
    - Instance type: `t3.medium`
    - Key pair: `orb-kp` (or your existing key)
    - Network settings:
      - Don't include in launch template (will be set by ASG)
    - Security groups: orbwatch-sg
    - IAM instance profile: `ecsInstanceRole`
    - Storage: 30 GB gp2
    - Advanced details → User data:
      ```bash
      #!/bin/bash
      sudo yum install -y ecs-init
      sudo echo ECS_CLUSTER="orbwatch-cluster" | sudo tee /etc/ecs/ecs.config
      sudo systemctl start docker
      sudo systemctl enable --now --no-block ecs.service
      ```

17. **Create Auto Scaling Group**
    - Navigate to: EC2 → Auto Scaling Groups → Create Auto Scaling group
    - Name: `orbwatch-asg`
    - Launch template: orbwatch-launch-template (Latest version)
    - VPC: orbwatch-vpc
    - Subnets: Both orbwatch-subnet1 and orbwatch-subnet2
    - **Skip** load balancer integration here (ECS service will handle it)
    - Group size:
      - Desired: 1
      - Minimum: 1
      - Maximum: 1
    - Scaling policies: None (capacity provider will manage)
    - **Create the ASG**
    - Wait for instance to launch and become healthy

18. **Create ECS Capacity Provider**
    - Navigate to: ECS → Clusters → orbwatch-cluster → Capacity providers → Create
    - Name: `orbwatch-capacity-provider`
    - Auto Scaling group: orbwatch-asg
    - Managed scaling: Enabled
      - Minimum scaling step size: 1
      - Maximum scaling step size: 1000
      - Target capacity: 100%
    - Managed termination protection: Disabled

19. **Update Cluster Capacity Providers**
    - Navigate to: ECS → Clusters → orbwatch-cluster → Update cluster
    - Add capacity provider: orbwatch-capacity-provider
    - Default capacity provider strategy:
      - Capacity provider: orbwatch-capacity-provider
      - Base: 1
      - Weight: 100

### Phase 6: ECS Service & DNS

20. **Create ECS Service**
    - Navigate to: ECS → Clusters → orbwatch-cluster → Services → Create
    - Launch type: EC2
    - Task definition: orbwatch-task-definition (latest)
    - Service name: `orbwatch-service`
    - Number of tasks: 1
    - Deployment type: Rolling update
    - Capacity provider strategy:
      - Capacity provider: orbwatch-capacity-provider
      - Base: 1
      - Weight: 100
    - Load balancer type: Application Load Balancer
      - Load balancer: orbwatch-alb
      - Container: orbwatch:80
      - Target group: orbwatch-target-group
    - Service discovery: Disabled
    - Auto Scaling: Disabled
    - **Create service**
    - Wait for task to start running

21. **Create Route53 DNS Record**
    - Navigate to: Route53 → Hosted zones → (your zone)
    - Create record:
      - Name: `orbwatch.khoah.net`
      - Type: A (Alias)
      - Alias to: Application Load Balancer
      - Region: us-west-1
      - Load balancer: orbwatch-alb
      - Evaluate target health: Yes

### Verification Steps

After completing all steps:

1. **Check ECS Container Instance**: ECS → Clusters → orbwatch-cluster → ECS Instances → Should see 1 instance
2. **Check ECS Task**: ECS → Clusters → orbwatch-cluster → Tasks → Should see 1 running task
3. **Check Target Group Health**: EC2 → Target Groups → orbwatch-target-group → Targets tab → Should be "healthy"
4. **Test ALB**: Copy ALB DNS name, open in browser → Should see your application
5. **Test DNS**: Open `https://orbwatch.khoah.net` → Should see your application

---

## Summary

**Key Concepts:**
- **ECS EC2 mode** means you manage the underlying EC2 instances
- **Auto Scaling Group** provides the EC2 instances
- **User data script** registers EC2 instances with ECS cluster
- **Capacity Provider** links ASG to ECS for intelligent scaling
- **ECS Service** manages your containers and integrates with ALB
- **ALB** routes traffic to EC2 instances where containers run
- **Bridge networking** maps container ports to host ports

**The magic happens when:**
1. ASG launches EC2 instance
2. User data registers it with ECS cluster
3. ECS Service places tasks on the instance
4. ECS Service registers instance with target group
5. ALB routes traffic to the instance/container
