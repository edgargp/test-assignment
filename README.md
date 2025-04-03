# Test Assignment

This repository contains the solution to the AWS Technical Assignment. 
The goal of this assignment is to deploy and manage a highly available, secure, and monitored AWS environment following best practices.


## Prerequisites

To work with this repository, you need to have the following packages installed:

- Terraform
- AWS CLI
- Python 3
- Packer

## Running the Python Script Locally

To run the Python script locally, follow these steps:

1. Install the virtual environment package if you haven't already:
   ```sh
   python3 -m pip install --user virtualenv
   ```

2. Create a virtual environment:
   ```sh
   python3 -m venv venv
   ```

3. Activate the virtual environment:
   - On macOS/Linux:
     ```sh
     source venv/bin/activate
     ```
   - On Windows:
     ```sh
     venv\Scripts\activate
     ```

4. Install the required packages:
   ```sh
   pip install -r requirements.txt
   ```

5. Run the script:
   ```sh
   python3 server.py
   ```

### API Endpoints

The Python application provides the following endpoints:

- `/` – Retrieves the EC2 hostname from metadata and returns it.
- `/healthcheck` – Used by the Application Load Balancer (ALB) to check EC2 health.
- `/terminate-instance` – Changes the `/healthcheck` response code from `200` to `404`.

## Deploying the Project

To deploy the project, follow these steps:

1. Ensure you have AWS default credentials configured.
2. Create an S3 bucket in your AWS account for the Terraform backend (e.g., `test-assignment-terraform`).
3. Once the above steps are completed, you can begin deploying the infrastructure.

### Building an AMI with Packer

**What is Packer?**
Packer is a tool for creating machine images for various platforms, including AWS, by automating the process of configuring and provisioning instances.

To build an AMI image:

1. Ensure you have the latest version of Packer installed.
2. Navigate to the `packer` directory:
   ```sh
   cd packer
   ```
3. Run the following command to build the AMI:
   ```sh
   packer build aws-ami-packer.json
   ```

Packer will launch an instance, execute the `script.sh` file, and upon successful execution, create an AMI named `python-app-ami`. The instance will then be terminated automatically.

### Deploying Infrastructure with Terraform

Once the AMI is created, you can proceed with deploying the infrastructure using Terraform:

1. Navigate to the main repository folder and initialize Terraform:
   ```sh
   terraform init
   ```
2. Review the execution plan:
   ```sh
   terraform plan
   ```
3. Apply the Terraform configuration:
   ```sh
   terraform apply
   ```

### Infrastructure Overview

Running the Terraform code will create the following resources:

- A new VPC with 3 public and 3 private subnets.
- Two EC2 instances using the AMI created earlier.
- An Auto Scaling Group with an Application Load Balancer.
- Other necessary AWS services.

After deployment, Terraform will output the ALB DNS name. Accessing this URL in a browser should display the hostname of an EC2 instance.

---

This completes the setup and deployment process. Happy coding!
