variable "region" {
    default = "us-east-1"
}
#####################################
################|VPC|################
#####################################
variable "vpc_cidr" {
    default = "10.0.0.0/16"
}
####################################
##############|Subnet|##############
####################################

##############|Subnet Availability_Zone|##############
variable "pub-sub1-az" {
    default = "us-east-1a"
}
variable "pub-sub2-az" {
    default = "us-east-1b"
}
variable "pvt-sub1-az" {
    default = "us-east-1c"
}
variable "pvt-sub2-az" {
    default = "us-east-1d"
}
##############|Subnet Cidr|##############
variable "pub-sub1-cidr" {
    default = "10.0.1.0/24"
}
variable "pub-sub2-cidr" {
    default = "10.0.2.0/24"
}
variable "pvt-sub1-cidr" {
    default = "10.0.3.0/24"
}
variable "pvt-sub2-cidr" {
    default = "10.0.4.0/24"
}
####################################
############|DATA BASE|#############
####################################

##############|DB USER & PASSWORD|##############
variable "db-username" {
    default = "admin"
}
variable "db-password" {
    default = "your password"
    sensitive = true
}
#####################################
################|EC2|################
#####################################

##############|AMI|##############
variable "ami" {
    default = "ami-00ca32bbc84273381" 
}

##############|Instance Type|##############
variable "instance_type" {
     default = "t3.nano"
}

##############|KEY PARI|##############
variable "key_pari" {
    default = "your key"
}
