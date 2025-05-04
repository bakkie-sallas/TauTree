variable "aws_region" {
  description = "AWS region for the cluster"
  default     = "ap-southeast-2"  # Change to your region
}
variable "aws_profile" {
  description = "CLI name"
  default = "wilkenAdmin"
}
variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = "yaylabs-eks-cluster"
}

variable "docker_image" {
  description = "Docker image for the React app"
  default = "ulfsark/tauTree:latest"
}

variable "domain_name" {
  description = "domain name"
  default = "yaylabs.co.nz"
}
