variable "aws_region" {
  description = "AWS region where the lab will be created."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Prefix used for resource names."
  type        = string
  default     = "security-lab"
}

variable "key_name" {
  description = "Optional EC2 key pair name. SSM can be used when this is null."
  type        = string
  default     = null
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH to the instances. Replace the default before applying."
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_types" {
  description = "Instance type for each role. Wazuh needs more memory than the other roles."
  type        = object({ waf = string, siem = string, juiceshop = string })
  default = {
    waf       = "t3.small"
    siem      = "t3.large"
    juiceshop = "t3.small"
  }
}
