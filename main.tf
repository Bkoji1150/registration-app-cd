

################################################################################
# CONFIGURE BACKEND
################################################################################

terraform {
  required_version = ">=1.1.0"

  backend "s3" {
    bucket         = "kojitechs.aws.eks.with.terraform.tf" # s3 bucket 
    key            = "path/env/registration-app-cd"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = "true"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.16.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

# data source romote state 
data "terraform_remote_state" "this" {
  backend = "s3"

  config = {
    region = "us-east-1"
    bucket = "kojitechs.aws.eks.with.terraform.tf"
    key    = "path/env/kojitechs-ci-cd-demo-infra-pipeline-tf"
  }
}

locals {
  kubernetes_secrets     = data.terraform_remote_state.this.outputs
  kubernetes_endpoint    = local.kubernetes_secrets.cluster_endpoint
  cluster_ca_certificate = base64decode(local.kubernetes_secrets.cluster_certificate_authority_data)
  cluster_id             = local.kubernetes_secrets.cluster_id
  token                  = data.aws_eks_cluster_auth.cluster.token

  ### network configuration imported 
  vpc_id                     = local.kubernetes_secrets.vpc_id
  private_subnet             = local.kubernetes_secrets.private_subnets
  eks_cluster_security_group = local.kubernetes_secrets.cluster_primary_security_group_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_id
}

provider "kubernetes" {
  host                   = local.kubernetes_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.token
}

provider "kubectl" {
  host                   = local.kubernetes_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.token
}

###############################
# kubernetes deployment
#################################
resource "kubernetes_deployment_v1" "this" {
  metadata {
    name = "registration-app"
    labels = {
      app : "registration-app"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app : "registration-app"
      }
    }
    template {
      metadata {
        labels = {
          app : "registration-app"
        }
      }
      spec {
        container {
          image = "735972722491.dkr.ecr.us-east-1.amazonaws.com/ci-cd-demo-kojitechs-webapp:${var.container_version}"
          name  = "registration-app"
          port {
            container_port = "8080"
          }
          env {
            name  = "DB_HOSTNAME"
            value = aws_db_instance.registration_app_db.address
          }
          env {
            name  = "DB_PORT"
            value = var.port
          }
          env {
            name  = "DB_NAME"
            value = var.db_name
          }
          env {
            name  = "DB_USERNAME"
            value = var.username
          }
          env {
            name  = "DB_PASSWORD"
            value = random_password.password.result
          }
        }
      }
    }
  }
}

###############################
# kubernetes load balancer service
#################################

resource "kubernetes_service_v1" "alb_service" {
  metadata {
    name = "registration-app-nlb-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb" # To create Network Load Balancer  
    }
  }
  spec {
    selector = {
      app = "registration-app"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}

###############################
# kubernetes service of NodePort
#################################

resource "kubernetes_service_v1" "nodeport_service" {
  metadata {
    name = "registration-app-service"
  }
  spec {
    selector = {
      app = "registration-app"
    }


    port {
      name        = "http"
      port        = 80
      target_port = 8080
      node_port   = 31280
    }
    type = "NodePort"
  }
}