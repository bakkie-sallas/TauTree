// cluster.tf

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile  // e.g., using an SSO-backed admin profile
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "tauTree" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "tauTree-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.tauTree.id
  cidr_block              = cidrsubnet(aws_vpc.tauTree.cidr_block, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "tauTree-public-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tauTree.id
  tags = {
    Name = "tauTree-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.tauTree.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "tauTree-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.33.1"  // specify a version that supports your desired features
  cluster_name    = var.cluster_name
  cluster_version = "1.32"

  vpc_id     = aws_vpc.tauTree.id
  subnet_ids = aws_subnet.public[*].id

  // Expose the API endpoint publicly and restrict access.
  cluster_endpoint_public_access           = true
  cluster_endpoint_public_access_cidrs       = [
    "139.180.101.255/32",
    "188.125.181.105/32",
    "0.0.0.0/0"
  ]
  cluster_endpoint_private_access            = false

  // NOTE: We are not using map_roles here.
}

#############################
# IAM Resources for Node Group
#############################

// Create a dedicated IAM role for the worker nodes.
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node_role" {
  name               = "tauTree-node-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

// Attach the required managed policies for EKS worker nodes.
resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#############################
# (Optional) Additional IAM Resources
#############################

// Define IAM users if needed (ensure unique resource names)
resource "aws_iam_user" "tauTree" {
  name = "tauTree-user"
}

resource "aws_iam_user" "wilken" {
  name = "Wilken"
}

resource "aws_iam_group" "tauTree_group" {
  name = "tauTree-group"
}

data "aws_iam_policy_document" "tauTree_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "tauTree_policy" {
  name        = "tauTree-policy"
  description = "A tauTree policy"
  policy      = data.aws_iam_policy_document.tauTree_policy_doc.json
}

resource "aws_iam_policy_attachment" "tauTree_attachment" {
  name       = "tauTree-attachment"
  users      = [aws_iam_user.wilken.name, aws_iam_user.tauTree.name]
  roles      = [aws_iam_role.node_role.name]
  groups     = [aws_iam_group.tauTree_group.name]
  policy_arn = aws_iam_policy.tauTree_policy.arn
}

#############################
# EKS Managed Node Group Resource
#############################

resource "aws_eks_node_group" "tauTree_ng" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "tauTree_ng"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.ecr_readonly,
    aws_iam_role_policy_attachment.eks_cni,
  ]
}


#############################
# Patch EKS Access Entry using a null_resource (local-exec)
#############################
resource "null_resource" "eks_access_entry" {
  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command = "try { aws eks delete-access-entry --cluster-name ${module.eks.cluster_name} --principal-arn 'arn:aws:iam::399694407131:role/aws-reserved/sso.amazonaws.com/ap-southeast-2/AWSReservedSSO_AdministratorAccess_d73193673eefe60e' --profile ${var.aws_profile} } catch {} ; aws eks create-access-entry --cluster-name ${module.eks.cluster_name} --principal-arn 'arn:aws:iam::399694407131:role/aws-reserved/sso.amazonaws.com/ap-southeast-2/AWSReservedSSO_AdministratorAccess_d73193673eefe60e' --username 'Wilken' --kubernetes-groups 'eks-admin' --profile ${var.aws_profile}"
  }
  depends_on = [module.eks]
}

 resource "aws_eks_access_policy_association" "admin" {
   cluster_name  = module.eks.cluster_name
   principal_arn = "arn:aws:iam::399694407131:role/aws-reserved/sso.amazonaws.com/ap-southeast-2/AWSReservedSSO_AdministratorAccess_d73193673eefe60e"
   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

   access_scope {
     type = "cluster"   # grant cluster-wide admin rights
   }

   # ensure the CLI-created access entry is in place first
   depends_on = [null_resource.eks_access_entry]
 }