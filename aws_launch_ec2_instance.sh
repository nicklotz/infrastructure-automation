#!/bin/bash
# Script to automate launching of AWS EC2 instances
# THE FOLLOWING VARIABLES MUST BE SET TO VALID VALUES FOR SCRIPT TO WORK:
	# INSTANCE_AMI
	# INSTANCE_SIZE
	# REGION
	# VPC_ID
	# SGROUP_LABEL
	# KEY_LABEL
# ENSURE THESE VARIABLES ARE APPROPRIATELY SET!

# Set environmental variables
DATETIME="$(date +"%m-%d-%Y-%T")"	# Date and time of creation
INSTANCE_AMI="ami-e3ef329b"		# Fill in with AWS AMI image (generally of form "ami-<string>"
INSTANCE_SIZE="t2.micro"		# Fill in with EC2 instance type (e.g. "t2.micro")
REGION="us-west-2"			# Fill in with region that instance is held in (e.g. "us-west-2")

# The following creates specifies the security group name that will hold the instance(s)
# If s-group does not yet exist, will create new one within default VPC
# Currently, script only supports specifying the name of the group (not ID)
# Therefore, only specify s-group if within default VPC, as non-default VPC requires s-group ID

VPC_ID = "vpc-abc1234" 			# Fill in with vpc ID of default VPC
SGROUP_LABEL="___myNetwork__"		# Fill in with name of security group
aws ec2 create-security-group --group-name "$SGROUP_LABEL" --description "Security group for my environment" --vpc-id "$VPC_ID"

# Create key pair for ssh access to instance
# Saves key pair in home directory (can move to ~/.ssh if desired)

KEY_LABEL="___myAccessKey__"		# Fill in with what to name security key pair" 
aws ec2 create-key-pair --key-name "$KEY_LABEL" --query "KeyMaterial" --output text > ~/"$KEY_LABEL.pem"
sudo chmod 400 ~/"$KEY_LABEL.pem"	# Set read-only permission on the key file

# Enable SSH access from all endpoints provided they have access key
aws ec2 authorize-security-group-ingress --group-name "$SGROUP_LABEL" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$REGION" 

# Create and launch EC2 instance
# Note multiple identical instances can be launched using the --count flag
aws ec2 run-instances --image-id "$INSTANCE_AMI" --count 1 --instance-type "$INSTANCE_SIZE" --key-name "$KEY_LABEL" --security-groups "$SGROUP_LABEL" --region "$REGION"
