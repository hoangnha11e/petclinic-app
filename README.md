# 1. Project Overview

This project aims to deploy the Spring PetClinic Microservices application on AWS EKS, applying DevOps tools and practices to automate the application build, deployment, and management processes. It combines Docker, Jenkins, Terraform, Kubernetes, Helm, and Argo CD to establish a complete CI/CD pipeline integrated with the GitOps approach.

The application source code is derived from the original [spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices) repository. (Special thanks to the authors for developing and sharing this project.)

The components retrieved from the original repository include eight microservice directories, originally prefixed with `spring-petclinic-` and renamed with the `petclinic-` prefix in this project; the `.mvn` directory and all its contents; and the `.editorconfig`, `.gitattributes`, `.gitignore`, `LICENSE`, `mvnw`, `mvnw.cmd`, and `pom.xml` files. All these components are stored in this project's `petclinic-app` repository.

The project is organized into three separate repositories:

- **Application Repository** (`petclinic-app`) — You are here
- **GitOps Repository** (`petclinic-gitops`) — https://github.com/hoangnha11e/petclinic-gitops
- **Infrastructure Repository** (`petclinic-infra`) — https://github.com/hoangnha11e/petclinic-infra

The project uses the following Docker Hub repositories to store the container images of its eight microservices:

- **Admin Server** (`petclinic-admin-server`) — 
https://hub.docker.com/repository/docker/hoangnha11e/petclinic-admin-server
- **API Gateway** (`petclinic-api-gateway`) — 
https://hub.docker.com/repository/docker/hoangnha11e/petclinic-api-gateway
- **Config Server** (`petclinic-config-server`) — 
https://hub.docker.com/repository/docker/hoangnha11e/petclinic-config-server
- **Customers Service** (`petclinic-customers-service`) — 
https://hub.docker.com/repository/docker/hoangnha11e/petclinic-customers-service
- **Discovery Server** (`petclinic-discovery-server`) — 
https://hub.docker.com/repository/docker/hoangnha11e/petclinic-discovery-server
- **GenAI Service** (`petclinic-genai-service`) — 
https://hub.docker.com/repository/docker/hoangnha11e/petclinic-genai-service
- **Vets Service** (`petclinic-vets-service`) — 
https://hub.docker.com/repository/docker/hoangnha11e/petclinic-vets-service
- **Visits Service** (`petclinic-visits-service`) — 
https://hub.docker.com/repository/docker/hoangnha11e/petclinic-visits-service

# 2. Techstack

<table align="center" width="100%">
  <tr align="center">
    <td width="14.28%">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/docker/docker-original.svg" width="90" height="90" alt="Docker" />
      <br>Docker
    </td>
    <td width="14.28%">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/jenkins/jenkins-original.svg" width="90" height="90" alt="Jenkins" />
      <br>Jenkins
    </td>
    <td width="14.28%">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@master/icons/amazonwebservices/amazonwebservices-original.svg" width="90" height="90" alt="AWS" />
      <br>AWS
    </td>
    <td width="14.28%">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/terraform/terraform-original.svg" width="90" height="90" alt="Terraform" />
      <br>Terraform
    </td>
    <td width="14.28%">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/kubernetes/kubernetes-plain.svg" width="90" height="90" alt="Kubernetes" />
      <br>Kubernetes
    </td>
    <td width="14.28%">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/helm/helm-original.svg" width="90" height="90" alt="Helm" />
      <br>Helm
    </td>
    <td width="14.28%">
      <img src="https://argo-cd.readthedocs.io/en/stable/assets/logo.png" width="90" height="90" alt="Argo CD" />
      <br>Argo CD
    </td>
  </tr>
</table>

<p align="center">
  <sub>
    Technology names and logos are trademarks of their respective owners.
    Their use is for identification purposes only and does not imply endorsement or affiliation.
  </sub>
</p>

# 3. AWS Architecture

The entire project infrastructure is provisioned and managed using **Terraform** on AWS in the Singapore region (`ap-southeast-1`).

![AWS Architecture](./assets/AWS%20Architecture.svg)

**AWS VPC**

The network infrastructure is built using Amazon VPC, consisting of Public and Private Subnets.

- **Public Subnet:** Hosts the Application Load Balancer and NAT Gateway to handle incoming traffic from the Internet and provide outbound connectivity for resources in the Private Subnet.
- **Private Subnet:** Hosts Amazon EKS Worker Nodes and Amazon RDS, keeping application workloads and databases from being directly exposed to the Internet.
- **Internet Gateway:** Attached to the VPC, providing connectivity between the VPC and the Internet.

**Application Load Balancer**

The Application Load Balancer (ALB) is deployed in the Public Subnet to receive incoming traffic from external users and forward requests to the API Gateway of the microservices application running on EKS.

**Application Configuration**

The microservices retrieve their application configurations from the `spring-petclinic-microservices-config` repository on GitHub through the Config Server. The NAT Gateway provides outbound connectivity, allowing components in the Private Subnet to access this repository.

**AWS EKS**

Amazon EKS serves as the platform for deploying and running the microservices application and its supporting components.

- **EKS Control Plane:** Managed by AWS, responsible for orchestrating and maintaining the state of the Kubernetes Cluster.
- **EC2 Worker Nodes:** Run in the Private Subnet and provide computing resources for application pods.
- **Microservice Apps:** Consist of the services that make up the Spring PetClinic application.
- **Supporting Components:** Include Metrics Server, Cluster Autoscaler, External Secrets Operator, and Argo CD.

**AWS RDS**

Amazon RDS is deployed in the Private Subnet to host the database for the microservices application. Placing the database in a private network helps prevent direct external access.

**AWS IAM**

AWS IAM manages identities, IAM Roles, and access permissions for system components interacting with AWS services. These permissions allow authorized components to perform the necessary operations on their respective resources.

**Pod Scaling**

Metrics Server collects CPU and memory utilization metrics from pods running on Worker Nodes and exposes them through the Kubernetes Metrics API. HPA uses this data to automatically determine when to scale the number of application pods up or down.

**Node Scaling**

Cluster Autoscaler monitors pod scheduling status and detects pods that cannot be scheduled due to insufficient resources. When additional computing capacity is required, Cluster Autoscaler requests the Auto Scaling Group to scale out the node group.

The Auto Scaling Group manages the number of EC2 Worker Nodes, allowing the EKS Cluster to automatically scale its computing capacity up or down based on demand.

**Secret Management**

AWS Secrets Manager is used to store sensitive application information. External Secrets Operator retrieves these secrets and synchronizes them as Kubernetes Secrets within the EKS Cluster for application pods to use.

**GitOps**

Argo CD monitors the `petclinic-gitops` repository on GitHub, which stores the desired deployment state of the application. When changes are made to the repository, Argo CD detects them and synchronizes the Kubernetes resources in the EKS Cluster with the configurations defined in Git.

**Terraform State**

Terraform uses Amazon S3 as a remote backend to store the Terraform State. This provides remote state storage, allowing Terraform to track and manage the AWS resources that have been provisioned.

# 4. Pipeline Flow

The project uses Jenkins to automate application builds, deployments, and infrastructure management. The workflow is divided into two main pipelines: **Application Pipeline** and **Infrastructure Pipeline**, working together with Argo CD to implement GitOps-based application deployment.

![Pipeline Flow](./assets/Pipeline%20Flow.svg)

**Application Pipeline**

1. **Pipeline Trigger:** When changes are pushed to the `petclinic-app` repository on GitHub, GitHub sends a webhook to the Jenkins Controller to trigger the application pipeline.
2. **Build and Push Image:** The Jenkins Controller assigns the build task to a Jenkins Build Agent. The agent builds the Docker image of the corresponding microservice and pushes it to Docker Hub.
3. **Update Image Tag:** After successfully pushing the image, the Build Agent uses `yq` to update the corresponding image tag in the `petclinic-gitops` repository.
4. **GitOps Deployment:** Argo CD detects changes in the GitOps repository and synchronizes the updated Helm configuration with the EKS Cluster. Kubernetes then pulls the new image from Docker Hub and deploys the updated application version.

**Infrastructure Pipeline**

1. **Pipeline Trigger:** When changes are pushed to the `petclinic-infra` repository on GitHub, GitHub sends a webhook to the Jenkins Controller to trigger the infrastructure pipeline.
2. **Infrastructure Deployment:** The Jenkins Controller assigns the task to the Jenkins Infra Agent. The agent uses Terraform to plan and apply infrastructure changes. The pipeline requires approval before executing `terraform apply` for the EKS Cluster, RDS Instance, and other Terraform-managed resources.
3. **Database Accounts and Secrets Management:** The Jenkins Infra Agent creates secrets in AWS Secrets Manager and database accounts in RDS when needed. This step requires approval before execution.
4. **Secrets Synchronization:** External Secrets Operator runs inside EKS, retrieves secret values from AWS Secrets Manager, and creates or updates Kubernetes Secrets in the EKS Cluster. Application pods can then use the synchronized secrets to access the database.
5. **Infrastructure Drift Detection:** The pipeline is scheduled to run once every hour to check the infrastructure state using Terraform Plan. If any drift is detected between the actual infrastructure and the Terraform configuration, the pipeline requests approval before executing `terraform apply` to reconcile the infrastructure with the desired state.
