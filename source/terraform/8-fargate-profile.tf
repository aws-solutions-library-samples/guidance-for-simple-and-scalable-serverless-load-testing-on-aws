# Fargate Pod Execution Role
resource "aws_iam_role" "eks_fargate_pod_execution_role" {
  name = local.fargate_pod_execution_role_name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks-fargate-pods.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach required policy to fargate pod execution role
resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role = aws_iam_role.eks_fargate_pod_execution_role.name

  depends_on = [
    aws_iam_role.eks_fargate_pod_execution_role
  ]
}

# Fargate Profile
resource "aws_eks_fargate_profile" "locust_fargate_profile" {
  cluster_name = local.eks_cluster_name
  fargate_profile_name = local.fargate_profile_name
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  subnet_ids = concat(aws_subnet.private[*].id)

  selector {
    namespace = "default"
  }

  selector {
    namespace = "kube-system"

    labels = {
      "k8s-app" = "kube-dns"
    }
  }
  
  selector {
    namespace = local.locust_namespace
  }

  tags = {
    "Name" = local.fargate_profile_name
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role.eks_fargate_pod_execution_role
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "coredns"

  # Optional: Specify the version of CoreDNS to deploy
  # addon_version = "v1.11.1-eksbuild.8"

  depends_on = [
    aws_eks_fargate_profile.locust_fargate_profile
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni"

  # Optional: Specify the version of the VPC CNI to deploy
  # addon_version = "v1.18.1-eksbuild.3"

  depends_on = [
    aws_eks_fargate_profile.locust_fargate_profile
  ]
}