# Simple & Scalable Serverless Load Testing on AWS

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deployment steps](#deployment-steps)
    * [1. Creating the infrastructure with Terraform](#1-creating-the-infrastructure-with-terraform)
    * [2. Creating a Locust load testing script](#2-creating-a-locust-load-testing-script)
    * [3. Deploying the Kubernetes resource files](#3-deploying-the-kubernetes-resource-files)
        + [3a. ConfigMap deployment](#3a-configmap-deployment)
        + [3b. Custom Docker image deployment](#3b-custom-docker-image-deployment)
    * [5. Creating a ClusterIP service](#5-creating-a-clusterip-service)
    * [6. Deploying the resources](#-6deploying-the-resources)
- [Deployment validation](#deployment-validation)
- [Accessing the Locust dashboard](#accessing-the-locust-dashboard)
- [Starting and stopping a test](#starting-and-stopping-a-test)
- [Increasing and decreasing load-generating worker pods](#increasing-and-decreasing-load-generating-worker-pods)
- [Cost considerations](#cost-considerations)
    * [Pricing calculator](#pricing-calculator)
    * [EKS Fargate and pod configuration costs](#eks-fargate-and-pod-configuration-costs)
    * [NAT Gateway costs](#nat-gateway-costs)
    * [Data transfer costs](#data-transfer-costs)
- [Cleanup](#cleanup-required)

</br>

## Overview

Small and medium-sized game studios often perceive load testing as a complex and costly activity where the challenges and time investment far outweigh the benefits. Adding to that perception are solutions that are tailored towards financially sound, large enterprises and companies with dedicated load testing teams and in-house expertise. However, load testing isn’t reserved only for high-profile releases or big studios. They can provide valuable insights for studios of any size, without requiring massive budgets or infrastructure. Even modest load tests, simulating hundreds or a few thousand concurrent users can uncover performance bottlenecks, identify server scaling issues, and validate key systems.

The following solution is simple, secure, fully-managed and scalable. It is meant to introduce teams to load testing, help them run large scale tests, gain actionable insights and confidence, understand the value in the practice, and eventually grow and shape their own load testing strategy. The solution centers around [Amazon Elastic Kubernetes Service](https://aws.amazon.com/eks/), [AWS Fargate](https://aws.amazon.com/fargate/), and open-source load testing framework [Locust](https://locust.io/), and can be built upon as the team's proficiency and load testing program grows. For instance, teams can eventually take over the management of the underlying nodes to unlock further optimizations and cost savings, can add persistence layers (InfluxDB, Prometheus, Graphite, or AWS managed services), add more robust monitoring and observability layers (Grafana, New Relic, AWS CloudWatch), and even enhance alerting and notification capabilities (posting to SNS topics, sending email/SMS, posting to Slack channels).

![Architecture Diagram](ArchitectureDiagram.png)

The architecture diagram above shows an EKS cluster that could span multiple availability zones. Each availability zone could contain private and public subnets. The EKS cluster has a Fargate profile that includes all private subnets, and Fargate-managed EC2 instances are allocated within them, which contain the deployed Locust pods. There is one control pod and multiple workers, and a ClusterIP service that provides pods with internal IP addresses. The ClusterIP service allows for load balanced traffic, as well as communication between the pods in the cluster without exposing them directly to the internet. NAT Gateways provide the workloads in private subnets with the means to generate traffic towards an external endpoint. The load test operator manages the cluster and test through the terminal of their local machine, and interacts with the Locust control pod’s web dashboard via port forwarding through their local browser.

Note that while multiple availability zones provide the design with high availability and resiliency—both AWS best practices—a load testing cluster might not necessarily need it. Given their purpose and temporary nature, environment failures or test disruptions have little to no effect; they do not serve live traffic, do not interact with live user data nor impact user experience, and failed tests can be restarted. Because of this, the architecture can be refactored into having a single availability zone housing all public and private subnets, further minimizing complexity and decreasing cost.

</br>

## Prerequisites

Please take the time to install the following dependencies and to make sure you meet the following prerequisites before moving on:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), a powerful command-line tool provided by Amazon Web Services (AWS) that allows you to interact with various AWS services directly from your computer's terminal or command prompt.
- [Terraform](https://developer.hashicorp.com/terraform/install), an open-source infrastructure as code (IaC) software tool from HashiCorp that enables users to define and provision cloud infrastructure resources in a declarative way.
- [Kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html), a command-line tool used to interact with and manage Kubernetes clusters.
- An IAM principal with the necessary privileges to run the provided Terraform scripts and create the resources.

</br>

## Deployment steps

</br>

### 1. Creating the infrastructure with Terraform

The following Terraform files are provided:

| Terraform File  | Purpose |
| ------------- | ------------- |
| 1-variables.tf | Defines the region, availability zones, subnets, cidr ranges, and names to be used when creating the infrastructure and resources. Should be customized to better suit your needs |
| 2-providers.tf | Specifies information about the plugins that allow Terraform to interact with different platforms, services, and infrastructure components |
| 3-vpc.tf | Creates a dedicated load testing VPC and the VPC's default security group |
| 4-subnets.tf | Outlines the public and private subnets to create |
| 5-gateways.tf | Creates the Internet Gateway, NAT Gatewaysm and Elastic IPs used |
| 6-route-tables.tf | Specifies route tables for the subnets and the approprate routes to the Internet Gatewat and NAT Gateways |
| 7-eks.tf | Creates the Amazon EKS cluster and requires components |
| 8-fargate-profile.tf | Sets up the Fargate profile that defines the namespace and private subnets that workloads are to be launched in |

Once files have been customized (if needed), open the terminal and navigate to the folder containing the terraform configuration files. Verify beforehand that calling ```aws sts get-caller-identity``` returns the IAM principal you intend to use and has the necessary permissions to build the infrastructure.

Initialize the directory with ```terraform init```. This will download and install the providers used in the files. As a best practice, verify that the configuration files are syntactically valid and internally consistent with the ```terraform validate``` command.

When ready, apply the configuration and start creating the resources via ```terraform apply```. Before applying any changes, Terraform will print out the details of the plan and the resources it intends to create, update, and destroy. Confirm by typing ```yes``` when prompted, and Terraform will start to create the resources. The process should take around 30 minutes to finish.

> [!NOTE]
> It’s possible for a timeout error to occur near the end, related to the deployment of CoreDNS pods

```
Error: waiting for EKS Add-On (load-testing-eks-cluster:coredns) create: timeout while waiting for state to become 'ACTIVE' (last state: 'DEGRADED', timeout: 20m0s)

   with aws_eks_addon.coredns,
   on 8-fargate-profile.tf line 64, in resource "aws_eks_addon" "coredns":
   64: resource "aws_eks_addon" "coredns" {
```

If encountered, simply run ```terraform apply``` again. Terraform will focus only on the resources that are missing. It will re-deploy the CoreDNS pods, and should be successful the second time after a few minutes.

</br>

### 2. Creating a Locust load testing script

Locust load testing scripts are written in [Python](https://www.python.org/), a high-level, general-purpose programming language. Locust scripts benefit from being able to define flexible scenarios that take advantage of thousands of powerful third-party libraries, while remaining familiar and easy to read.

Learning to create complex Locust scripts falls outside the scope of this guide, but the [official documentation site for Locust](https://docs.locust.io/en/stable/quickstart.html) provides detailed information and script examples to get your journey started.

For the purposes of this guide, two sample scripts are used to illustrate how to define multiple test scripts. They issue a single GET request to a relative endpoint, as the target host is specified later in the control deployment file:

```
from locust import HttpUser, task, between

class test(HttpUser):
    wait_time = between(1, 3)

    @task
    def initial_request(self):
        self.client.get("/")
```

Depending on the deployment method used, the script will be included later through a ConfigMap file, or be added into a custom Docker image. In any case, **a custom load testing script that accurately simulates the real-world traffic patterns and user behavior of the system being tested must be created and provided**, as the quality and accuracy of the load testing results are heavily influenced by it.

</br>

### 3. Deploying the Kubernetes resource files 
            
The following Kubernetes resources files are provided:

| Kubernetes Resource File  | Purpose |
| ------------- | ------------- |
| namespace.yaml | Creates the namespace in the EKS cluster where the control and worker pods will be launched |
| control-deployment.yaml | Specifies the deployment configuration of and resources needed by the control pod |
| control-service.yaml | Defines the ClusterIP service to create to enable communication within the cluster |
| worker-deployment.yaml | Specifies the deployment configuration of and resources needed by the worker pods |
| configmap.yaml | (If using ConfigMap deployment) Defines the load testing script to use |
| Dockerfile | (If using custom image deployment) File describing the base Locust Docker image to use, and load testing scripts to include when creating the custom Docker image |
| script1.py / script2.py | (If using custom image deployment) Sample load testing scripts, to be replaced with custom scripts |

There are many ways to create deployments. This guide focuses on two:
- Using **ConfigMap** to provide the Pods with the Locust load testing script, and
- Building a custom **Docker image** from the base Locust image, containing multiple Locust testing scripts inside.

The first approach might be useful when dealing with one or more small scripts that might change frequently, while the second might be better suited for dealing with multiple large, static scripts for prolonged tests.

</br>

### 3a. ConfigMap deployment

TBD

</br>

### 3b. Custom Docker image deployment

TBD

</br>

## Deployment Validation  (required)

<Provide steps to validate a successful deployment, such as terminal output, verifying that the resource is created, status of the CloudFormation template, etc.>


**Examples:**

* Open CloudFormation console and verify the status of the template with the name starting with xxxxxx.
* If deployment is successful, you should see an active database instance with the name starting with <xxxxx> in        the RDS console.
*  Run the following CLI command to validate the deployment: ```aws cloudformation describe xxxxxxxxxxxxx```



## Running the Guidance (required)

<Provide instructions to run the Guidance with the sample data or input provided, and interpret the output received.> 

This section should include:

* Guidance inputs
* Commands to run
* Expected output (provide screenshot if possible)
* Output description



## Next Steps (required)

Provide suggestions and recommendations about how customers can modify the parameters and the components of the Guidance to further enhance it according to their requirements.


## Cleanup (required)

- Include detailed instructions, commands, and console actions to delete the deployed Guidance.
- If the Guidance requires manual deletion of resources, such as the content of an S3 bucket, please specify.



## FAQ, known issues, additional considerations, and limitations (optional)


**Known issues (optional)**

<If there are common known issues, or errors that can occur during the Guidance deployment, describe the issue and resolution steps here>


**Additional considerations (if applicable)**

<Include considerations the customer must know while using the Guidance, such as anti-patterns, or billing considerations.>

**Examples:**

- “This Guidance creates a public AWS bucket required for the use-case.”
- “This Guidance created an Amazon SageMaker notebook that is billed per hour irrespective of usage.”
- “This Guidance creates unauthenticated public API endpoints.”


Provide a link to the *GitHub issues page* for users to provide feedback.


**Example:** *“For any feedback, questions, or suggestions, please use the issues tab under this repo.”*

## Revisions (optional)

Document all notable changes to this project.

Consider formatting this section based on Keep a Changelog, and adhering to Semantic Versioning.

## Notices (optional)

Include a legal disclaimer

**Example:**
*Customers are responsible for making their own independent assessment of the information in this Guidance. This Guidance: (a) is for informational purposes only, (b) represents AWS current product offerings and practices, which are subject to change without notice, and (c) does not create any commitments or assurances from AWS and its affiliates, suppliers or licensors. AWS products or services are provided “as is” without warranties, representations, or conditions of any kind, whether express or implied. AWS responsibilities and liabilities to its customers are controlled by AWS agreements, and this Guidance is not part of, nor does it modify, any agreement between AWS and its customers.*


## Authors (optional)

Name of code contributors
