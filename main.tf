terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr              = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  region                = var.region
}

module "alb" {
  source = "./modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
  alb_sg_id         = module.vpc.alb_sg_id
}

module "asg" {
  source = "./modules/asg"

  ec2_sg_id          = module.vpc.ec2_sg_id
  private_subnet_ids = [module.vpc.private_subnet_1_id, module.vpc.private_subnet_2_id]
  target_group_arn   = module.alb.target_group_arn
  instance_type      = var.instance_type
}

module "monitoring" {
  source = "./modules/monitoring"

  alb_arn_suffix         = module.alb.alb_arn_suffix
  tg_arn_suffix          = module.alb.tg_arn_suffix
  autoscaling_group_name = module.asg.autoscaling_group_name
  alarm_email            = var.alarm_email
}

resource "aws_s3_bucket" "app" {
  bucket = "prod-app-bucket-${random_id.suffix.hex}"
  tags   = { Name = "prod-app-bucket" }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}