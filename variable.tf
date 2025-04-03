variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-3"
}


variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
  default     = "python-app-asg"
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 8
}




variable "trail_name" {
  description = "The name for the CloudTrail trail."
  type        = string
  default     = "main-account-trail"
}


variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "Security"
    ManagedBy   = "Terraform"
  }
}