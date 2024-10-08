# Simple & Scalable Serverless Load Testing on AWS

## Table of Contents

1. [Overview](#overview)
    - [Cost](#cost)
2. [Prerequisites](#prerequisites)
3. [Deployment steps](#deployment-steps)
    - [Creating the infrastructure with Terraform](#creating-the-infrastructure-with-terraform)
    - [Creating a sample Locust load testing script](#creating-a-sample-Locust-load-testing-script)
    - [Creating a Kubernetes namespace](#creating-a-kubernetes-namespace)
    - [Creating control and worker deployments](#creating-control-and-worker-deployments)
        * [ConfigMap version](#configmap-version)
        * [Custom Docker image version](#custom-docker-image-version)
    - [Creating a ClusterIP service](#creating-a-clusterip-service)
    - [Deploying the resources](#deploying-the-resources)
5. [Deployment validation](#deployment-validation)
7. [Accessing the Locust dashboard](#accessing-the-locust-dashboard)
8. [Starting and stopping a test](#starting-and-stopping-a-test)
9. [Increasing and decreasing load-generating worker pods](#increasing-and-decreasing-load-generating-worker-pods)
10. [Cost considerations](#cost-considerations)
    - [Pricing calculator](#pricing-calculator)
    - [EKS Fargate and pod configuration costs](#eks-fargate-and-pod-configuration-costs)
    - [NAT Gateway costs](#nat-gateway-costs)
    - [Data transfer costs](#data-transfer-costs)
11. [Cleanup](#cleanup-required)

## Overview

Small and medium-sized game studios often perceive load testing as a complex and costly activity where the challenges and time investment far outweigh the benefits. Adding to that perception are solutions that are tailored towards financially sound, large enterprises and companies with dedicated load testing teams and in-house expertise. However, load testing isn’t reserved only for high-profile releases or big studios. They can provide valuable insights for studios of any size, without requiring massive budgets or infrastructure. Even modest load tests, simulating hundreds or a few thousand concurrent users can uncover performance bottlenecks, identify server scaling issues, and validate key systems.

The following solution is simple, secure, fully-managed and scalable. It is meant to introduce teams to load testing, help them run large scale tests, gain actionable insights and confidence, understand the value in the practice, and eventually grow and shape their own load testing strategy. The solution centers around [Amazon Elastic Kubernetes Service](https://aws.amazon.com/eks/), [AWS Fargate](https://aws.amazon.com/fargate/), and open-source load testing framework [Locust](https://locust.io/), and can be built upon as the team's proficiency and load testing program grows. For instance, teams can eventually take over the management of the underlying nodes to unlock further optimizations and cost savings, can add persistence layers (InfluxDB, Prometheus, Graphite, or AWS managed services), add more robust monitoring and observability layers (Grafana, New Relic, AWS CloudWatch), and even enhance alerting and notification capabilities (posting to SNS topics, sending email/SMS, posting to Slack channels).

![Architecture Diagram](ArchitectureDiagram.png)

The architecture diagram above shows an EKS cluster that could span multiple availability zones. Each availability zone could contain private and public subnets. The EKS cluster has a Fargate profile that includes all private subnets, and Fargate-managed EC2 instances are allocated within them, which contain the deployed Locust pods. There is one control pod and multiple workers, and a ClusterIP service that provides pods with internal IP addresses. The ClusterIP service allows for load balanced traffic, as well as communication between the pods in the cluster without exposing them directly to the internet. NAT Gateways provide the workloads in private subnets with the means to generate traffic towards an external endpoint. The load test operator manages the cluster and test through the terminal of their local machine, and interacts with the Locust control pod’s web dashboard via port forwarding through their local browser.

Note that while multiple availability zones provide the design with high availability and resiliency—both AWS best practices—a load testing cluster might not necessarily need it. Given their purpose and temporary nature, environment failures or test disruptions have little to no effect; they do not serve live traffic, do not interact with live user data nor impact user experience, and failed tests can be restarted. Because of this, the architecture can be refactored into having a single availability zone housing all public and private subnets, further minimizing complexity and decreasing cost.

### Cost

This section is for a high-level cost estimate. Think of a likely straightforward scenario with reasonable assumptions based on the problem the Guidance is trying to solve. Provide an in-depth cost breakdown table in this section below ( you should use AWS Pricing Calculator to generate cost breakdown ).

Start this section with the following boilerplate text:

_You are responsible for the cost of the AWS services used while running this Guidance. As of <month> <year>, the cost for running this Guidance with the default settings in the <Default AWS Region (Most likely will be US East (N. Virginia)) > is approximately $<n.nn> per month for processing ( <nnnnn> records )._

Replace this amount with the approximate cost for running your Guidance in the default Region. This estimate should be per month and for processing/serving resonable number of requests/entities.

Suggest you keep this boilerplate text:
_We recommend creating a [Budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html) through [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/) to help manage costs. Prices are subject to change. For full details, refer to the pricing webpage for each AWS service used in this Guidance._

### Sample Cost Table ( required )

**Note : Once you have created a sample cost table using AWS Pricing Calculator, copy the cost breakdown to below table and upload a PDF of the cost estimation on BuilderSpace. Do not add the link to the pricing calculator in the ReadMe.**

The following table provides a sample cost breakdown for deploying this Guidance with the default parameters in the US East (N. Virginia) Region for one month.

| AWS service  | Dimensions | Cost [USD] |
| ----------- | ------------ | ------------ |
| Amazon API Gateway | 1,000,000 REST API calls per month  | $ 3.50month |
| Amazon Cognito | 1,000 active users per month without advanced security feature | $ 0.00 |

## Prerequisites

Please take the time to install the following dependencies and to make sure you meet the following prerequisites before moving on:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), a powerful command-line tool provided by Amazon Web Services (AWS) that allows you to interact with various AWS services directly from your computer's terminal or command prompt.
- [Terraform](https://developer.hashicorp.com/terraform/install), an open-source infrastructure as code (IaC) software tool from HashiCorp that enables users to define and provision cloud infrastructure resources in a declarative way.
- [Kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html), a command-line tool used to interact with and manage Kubernetes clusters.
- An IAM principal with the necessary privileges to run the provided Terraform scripts and create the resources.

## Deployment Steps

Deployment steps must be numbered, comprehensive, and usable to customers at any level of AWS expertise. The steps must include the precise commands to run, and describe the action it performs.

* All steps must be numbered.
* If the step requires manual actions from the AWS console, include a screenshot if possible.
* The steps must start with the following command to clone the repo. ```git clone xxxxxxx```
* If applicable, provide instructions to create the Python virtual environment, and installing the packages using ```requirement.txt```.
* If applicable, provide instructions to capture the deployed resource ARN or ID using the CLI command (recommended), or console action.

 
**Example:**

1. Clone the repo using command ```git clone xxxxxxxxxx```
2. cd to the repo folder ```cd <repo-name>```
3. Install packages in requirements using command ```pip install requirement.txt```
4. Edit content of **file-name** and replace **s3-bucket** with the bucket name in your account.
5. Run this command to deploy the stack ```cdk deploy``` 
6. Capture the domain name created by running this CLI command ```aws apigateway ............```



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
