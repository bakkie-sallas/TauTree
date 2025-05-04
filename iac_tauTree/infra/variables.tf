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

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}
#variable "docker_username" { type = string }
#variable "docker_password" { type = string }
#variable "docker_email"    { type = string }
