# AWS Production Infrastructure

A production-ready AWS infrastructure built using Terraform for a SaaS web application. This project covers networking, compute, security, monitoring, and CI/CD automation.

---

## Architecture Overview

```
Internet
    |
Internet Gateway
    |
 -----------------------------------------------
|               VPC (10.0.0.0/16)              |
|                                               |
|  [ Public Subnet 1 ]   [ Public Subnet 2 ]   |
|  [ Load Balancer   ]   [ NAT Gateway    ]    |
|     us-east-1a             us-east-1b         |
|                                               |
|  [ Private Subnet 1 ]  [ Private Subnet 2 ]  |
|  [ EC2 - NGINX     ]   [ EC2 - NGINX    ]    |
|     us-east-1a             us-east-1b         |
|                                               |
 -----------------------------------------------
```

---

## Tech Stack

- **Infrastructure as Code:** Terraform (modular)
- **Cloud Provider:** AWS (us-east-1)
- **Web Server:** NGINX
- **CI/CD:** GitHub Actions
- **Monitoring:** CloudWatch
- **State Management:** S3 Remote Backend

---

## Deployment Steps

### Prerequisites

- Terraform v1.14+
- AWS CLI configured (`aws configure`)
- Git

### Steps

1. Clone the repository:
```bash
git clone https://github.com/akkivaidya/aws-production-infra.git
cd aws-production-infra
```

2. Initialize Terraform:
```bash
terraform init
```

3. Preview the infrastructure:
```bash
terraform plan -var="alarm_email=rakeshvaidya1996@email.com"
```

4. Deploy:
```bash
terraform apply -var="alarm_email=rakeshvaidya1996@email.com"
```

5. Access the application via the ALB DNS name shown in the output:
```
alb_dns_name = "prod-alb-1763024188.us-east-1.elb.amazonaws.com"
```

### Destroy (to avoid charges)
```bash
terraform destroy -var="alarm_email=rakeshvaidya1996@email.com"
```

---

## Architecture Decisions

### 1. Multi-AZ Deployment
The infrastructure spans two availability zones (us-east-1a and us-east-1b) to ensure high availability. If one AZ goes down, the other continues serving traffic.

### 2. Private Subnets for EC2
EC2 instances are placed in private subnets with no public IP addresses. All inbound traffic goes through the ALB, and outbound traffic goes through the NAT Gateway. This reduces the attack surface significantly.

### 3. Application Load Balancer
The ALB handles all incoming traffic and distributes it across EC2 instances. It also performs health checks and stops sending traffic to unhealthy instances automatically.

### 4. Auto Scaling Group
The ASG maintains a minimum of 2 instances and can scale up to 4. This ensures the application stays available even during traffic spikes or instance failures.

### 5. Modular Terraform
The Terraform code is split into modules (vpc, alb, asg, monitoring) for better readability, reusability, and maintainability.

### 6. S3 Remote Backend
Terraform state is stored in S3 so that both local and CI/CD environments share the same state, preventing conflicts.

---

## Security Measures

| Measure | Implementation |
|---|---|
| No public EC2 instances | EC2 in private subnets only |
| Least privilege security groups | EC2 only accepts traffic from ALB on port 80 |
| IAM roles | No static access keys — EC2 uses IAM instance profile |
| Encrypted EBS volumes | `encrypted = true` in launch template |
| S3 public access blocked | `aws_s3_bucket_public_access_block` resource |
| No secrets in code | Secrets passed via environment variables and GitHub Secrets |

---

## Cost Estimate
> Cost can be reduced by using right-sized instances , Savings Plans, or running in a single AZ for non-production environments.

---

## Scaling Strategy

- **Horizontal scaling:** Auto Scaling Group automatically adds EC2 instances when CPU exceeds 80%
- **Load balancing:** ALB distributes traffic evenly across all healthy instances
- **Multi-AZ:** Traffic is served from both availability zones simultaneously
- **Future improvements:** Add RDS with read replicas, ElastiCache for session management, and CloudFront for global content delivery

---

## CI/CD Pipeline

Every push to the `main` branch triggers GitHub Actions which:
1. Initializes Terraform
2. Checks code formatting (`terraform fmt`)
3. Validates configuration (`terraform validate`)
4. Runs `terraform plan` to preview changes

Infrastructure changes are applied manually from the local machine using `terraform apply`.

---

## Module Structure

```
aws-production-infra/
├── main.tf               # Root module - connects all modules
├── variables.tf          # Input variables
├── outputs.tf            # Output values
├── terraform.tfvars      # Variable values (not committed)
└── modules/
    ├── vpc/              # VPC, subnets, IGW, NAT, route tables, security groups
    ├── alb/              # Application Load Balancer, target group, listener
    ├── asg/              # Launch template, Auto Scaling Group, IAM role
    └── monitoring/       # CloudWatch alarms, SNS, log group, budget alert
```
