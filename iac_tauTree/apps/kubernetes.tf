// kubernetes.tf
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile  // e.g., using an SSO-backed admin profile
}

// Bring in infra outputs (only cluster_endpoint for now)
data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../infra/terraform.tfstate"
  }
}

// AWS data sources to retrieve the cluster details
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

// Kubernetes provider configured against the EKS API
provider "kubernetes" {
  host                   = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

// Give the "eks-admin" group full cluster-admin rights
resource "kubernetes_cluster_role_binding" "eks_admin_binding" {
  metadata {
    name = "eks-admin-binding"
  }

  subject {
    kind      = "Group"
    name      = "eks-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_namespace" "wilken" {
  metadata {
    name = "wilken"
  }
}

resource "kubernetes_deployment" "react_app" {
  metadata {
    name      = "react-app"
    namespace = kubernetes_namespace.wilken.metadata[0].name
    labels = {
      app = "react-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "react-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "react-app"
        }
      }

      spec {
        container {
          name  = "react-app"
          image = var.docker_image  // e.g., "your-dockerhub-username/your-react-app:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "react_app" {
  metadata {
    name      = "react-app"
    namespace = kubernetes_namespace.wilken.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.react_app.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress" "react_app_ingress" {
  metadata {
    name      = "react-app-ingress"
    namespace = kubernetes_namespace.wilken.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
    }
  }

  spec {
    rule {
      host = var.domain_name  // e.g., "yaylabs.co.nz"

      http {
        path {
          path = "/wilken/*"
          backend {
            service_name = kubernetes_service.react_app.metadata[0].name
            service_port = 80
          }
        }
      }
    }
  }
}
