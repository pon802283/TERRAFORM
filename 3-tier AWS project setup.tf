##########|IAM|##########
resource "aws_iam_role" "pro-iam" { 
    name = "S3FullAccessPolicy"
    description = "Policy to allow s3"
    
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
    }
    ]
}
EOF

    tags = {
    Name = "S3FullAccessPolicy"
    }
}

resource "aws_iam_role_policy_attachment" "E2-attach-s3" {
    role = aws_iam_role.pro-iam.id
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2-s3-access" {
    name = "ec2_s3_access"
    role = aws_iam_role.pro-iam.name
    tags = {
        Name = "pro-ec2-s3-access"
    }
}

        #################################
        ###########|Create S3|###########
        #################################
# Create S3 bucket
resource "aws_s3_bucket" "pro_s3" {
    bucket = "tf-pro-s3-2025" # must be globally unique
    tags = {
    Name = "tf-pro-s3-2025"
    }
}

# Upload local folder to S3 under "aws-three-tier-web-architecture-workshop/"
resource "aws_s3_object" "aws_pro" {
    for_each = fileset("D:/AWS proj/aws-three-tier-web-architecture-workshop/application-code", "**")

    bucket = aws_s3_bucket.pro_s3.bucket
    key    = "aws-three-tier-web-architecture-workshop/${each.value}"
    source = "D:/AWS proj/aws-three-tier-web-architecture-workshop/application-code/${each.value}"
    etag   = filemd5("D:/AWS proj/aws-three-tier-web-architecture-workshop/application-code/${each.value}")
}

provider "aws" {
    region = var.region
}
###########################################
#############|Create aws vpc|##############
###########################################
resource "aws_vpc" "sankar" {
    cidr_block = var.vpc_cidr
    tags = {
        Name = "project"
        }
}
#############################################
#############|Create aws subnet|#############
#############################################
#Create 2pub-subnet
resource "aws_subnet" "pub-sub1" {
    vpc_id = aws_vpc.sankar.id
    availability_zone = var.pub-sub1-az
    cidr_block = var.pub-sub1-cidr
    tags = {
        Name = "pro-pub-sub1"
    }
}
resource "aws_subnet" "pub-sub2" {
    vpc_id = aws_vpc.sankar.id
    availability_zone = var.pub-sub2-az
    cidr_block = var.pub-sub2-cidr
    tags = {
        Name = "pro-pub-sub2"
    }
}
#Create 2pvt-subnet
resource "aws_subnet" "pvt-sub1" {
    vpc_id = aws_vpc.sankar.id
    availability_zone = var.pvt-sub1-az
    cidr_block = var.pvt-sub1-cidr
    tags = {
        Name = "pro-pvt-sub1"
    }
}
resource "aws_subnet" "pvt-sub2" {
    vpc_id = aws_vpc.sankar.id
    availability_zone = var.pvt-sub2-az
    cidr_block = var.pvt-sub2-cidr
    tags = {
        Name = "pro-pvt-sub2"
}
}
#######################################
#############|Create IGW |#############
#######################################
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.sankar.id
    tags = {
        Name = "pro-IGW"
    }
}
####################################################
################|Create route table|################
####################################################
#pub
resource "aws_route_table" "pro-rt-pub" {
    vpc_id = aws_vpc.sankar.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
    Name = "pro-rt-pub"
    }
}
#pvt
resource "aws_route_table" "pro-rt-pvt" {
    vpc_id = aws_vpc.sankar.id
    tags = {
        Name = "pro-rt-pvt"
    }
}
##########################################################################################
##########|Associate Public & Private Subnets with Public & Private Route Table|##########
##########################################################################################

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "Pub_ass1" {
    subnet_id = aws_subnet.pub-sub1.id
    route_table_id = aws_route_table.pro-rt-pub.id
}
resource "aws_route_table_association" "pub_ass2" {
    subnet_id = aws_subnet.pub-sub2.id
    route_table_id = aws_route_table.pro-rt-pub.id
}
#Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "pvt_ass1" {
    subnet_id = aws_subnet.pvt-sub1.id
    route_table_id = aws_route_table.pro-rt-pvt.id
}
resource "aws_route_table_association" "pvt_ass2" {
    subnet_id = aws_subnet.pvt-sub2.id
    route_table_id = aws_route_table.pro-rt-pvt.id
}

###########################################
##########|Cerate Security Group|##########
###########################################

#ELB#
resource "aws_security_group" "ELB" {
    name = "ELB"
    description = "external load balancer"
    vpc_id = aws_vpc.sankar.id
    ingress {
        description = "Allow-only-HTTP"
        from_port = 80
        to_port =80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "Allow-only-all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
        Name = "Sg-ELB"
    }
}
#JS
resource "aws_security_group" "JS" {
    name = "js"
    description = "jserver"
    vpc_id = aws_vpc.sankar.id
    ingress {
        description = "Allow-only-SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "Allow-only-all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
        Name = "Sg-jserver"
    }
}
#web server
resource "aws_security_group" "web-server" {
    name = "web-server"
    description = "web-server"
    vpc_id = aws_vpc.sankar.id
    ingress {
        description = "Allow-only-ELB"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [ aws_security_group.ELB.id ]
    }
    egress {
        description = "Allow-only-all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
    Name = "Sg-Web-Server"
    }
}
#internal load balancer
resource "aws_security_group" "ILB" {
    name = "ILB"
    description = "ILB"
    vpc_id = aws_vpc.sankar.id
    ingress {
        description = "Allow-only-Web-Server"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [ aws_security_group.web-server.id ]
    }
    egress {
        description = "Allow-only-all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}
#app server
resource "aws_security_group" "app-server" {
    name = "app server"
    description = "app server"
    vpc_id = aws_vpc.sankar.id
    ingress {
        description = "Allow-only-ILB"
        from_port = 4000
        to_port = 4000
        protocol = "tcp"
        security_groups = [aws_security_group.ILB.id]
    }
    ingress {
        description = "Allow-only-js"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [ aws_security_group.JS.id ]
    }
    egress {
        description = "Allow-only-all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
        Name = "Sg-app-server"
    }
}
#Database
resource "aws_security_group" "rds-db" {
    name = "Database"
    description = "Database"
    vpc_id = aws_vpc.sankar.id
    ingress {
        description = "Allow-only- app-server"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [ aws_security_group.app-server.id ]
    }
    egress {
        description = "Allow-only-all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
        Name = "Sg-Database"
    }
}

    ##########################################
    ###############|Cerate RDS|###############
    ##########################################

###########################################
#########|Cerate RDS Subnet group|#########
###########################################
resource "aws_db_subnet_group" "pro-DB-sub" {
    name = "pro-db-sub"
    description = " db-for-project"
    #vpc_id = aws_vpc.sankar.id
    subnet_ids = [aws_subnet.pub-sub1.id,
                aws_subnet.pub-sub2.id,
                aws_subnet.pvt-sub1.id,
                aws_subnet.pvt-sub2.id]
    tags = {
        Name = "pro-db"
    }
}
##########################################
###########|Cerate DB Instance|###########
##########################################
resource "aws_db_instance" "proDBinstance" {
    identifier = "prodbinst"
    allocated_storage = "20"
    db_name = "proDBinstance"
    engine = "mysql"
    engine_version = "8.0.42"
    instance_class = "db.t3.micro"
    username = var.db-username
    password = var.db-password
    db_subnet_group_name = aws_db_subnet_group.pro-DB-sub.id
    vpc_security_group_ids = [ aws_security_group.rds-db.id ]
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot  = true
    deletion_protection = false
    tags = {
        Environment = "Sandbox"
        Name = "proDBinst"
    }
}

#####################################
#########|Create JS Server|##########
#####################################
resource "aws_instance" "pro-JS-server" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_pari
    availability_zone = var.pub-sub1-az
    subnet_id = aws_subnet.pub-sub1.id
    associate_public_ip_address = true
    security_groups = [ aws_security_group.JS.id ]
    secondary_private_ips = ["10.0.1.9"]
    
    user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y mariadb105-server

        mysql -h ${aws_db_instance.proDBinstance.address} -P 3306 -u admin -psankar-2002-08 <<EOSQL
        CREATE DATABASE IF NOT EXISTS webappdb;
        USE webappdb;
        CREATE TABLE IF NOT EXISTS transactions (
            id INT NOT NULL AUTO_INCREMENT,
            amount DECIMAL(10,2),
            description VARCHAR(100),
            PRIMARY KEY (id)
        );
        INSERT INTO transactions (amount, description) VALUES (400, 'groceries');
        INSERT INTO transactions (amount, description) VALUES (100, 'class');
        INSERT INTO transactions (amount, description) VALUES (200, 'other groceries');
        INSERT INTO transactions (amount, description) VALUES (10, 'brownies');
        EOSQL
    EOF
    tags = {
        Name = "pro-JS-servre"
    }
}

#####################################
#########|Create App Server|#########
#####################################
resource "aws_instance" "pro-app-server" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_pari
    availability_zone = var.pvt-sub1-az
    subnet_id = aws_subnet.pvt-sub1.id
    associate_public_ip_address = true
    security_groups = [aws_security_group.app-server.id ]
    secondary_private_ips = ["10.0.3.9"]
    user_data = <<-EOF
                #!/bin/bash
                # Update system
                yum update -y

                # Install Node Version Manager (NVM)
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
                export NVM_DIR="$HOME/.nvm"
                source $NVM_DIR/nvm.sh

                # Install Node.js 16
                nvm install 16
                nvm use 16

                # Install PM2 globally
                npm install -g pm2

                # Install AWS CLI
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                sudo ./aws/install

                # Download app code from S3 (replace tf-pro-s3-2025)
                aws s3 cp s3://tf-pro-s3-2025/app-tier/ /home/ec2-user/app-tier --recursive
                cd /home/ec2-user/app-tier

                # Install app dependencies
                npm install

                # Start Node.js app with PM2
                pm2 start index.js
                pm2 startup
                pm2 save

                EOF
    tags = {
    Name = "pro-app-server"
    }
}

#####################################
#########|Create Wep Server|#########
#####################################
resource "aws_instance" "pro-wep-server" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_pari
    subnet_id = aws_subnet.pvt-sub2.id
    availability_zone = var.pvt-sub2-az
    associate_public_ip_address = true
    security_groups = [ aws_security_group.web-server.id ]
    secondary_private_ips = ["10.0.4.9"]
    user_data = <<-EOF
                #!/bin/bash
                # Update system
                yum update -y
                #
                # Install Node Version Manager (NVM)
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
                export NVM_DIR="$HOME/.nvm"
                source $NVM_DIR/nvm.sh
                #
                # Install Node.js 16
                nvm install 16
                nvm use 16
                #
                # Install AWS CLI
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                sudo ./aws/install
                #
                # Download web tier code from S3 (replace tf-pro-s3-2025)
                aws s3 cp s3://tf-pro-s3-2025/web-tier/ /home/ec2-user/web-tier --recursive
                cd /home/ec2-user/web-tier
                #
                # Build React app
                npm install
                npm run build
                #
                # Install Nginx
                amazon-linux-extras enable nginx1
                yum install -y nginx
                #
                # Replace default nginx.conf with one from S3 (replace tf-pro-s3-2025)
                cd /etc/nginx
                rm -f nginx.conf
                aws s3 cp s3://tf-pro-s3-2025/nginx.conf nginx.conf
                #
                # Restart Nginx
                systemctl restart nginx
                systemctl enable nginx
                #
                # Ensure frontend files are accessible
                chmod -R 755 /home/ec2-user/web-tier
                #
                EOF
    tags = {
        Name = "pro-web-server"
    }
}

######################
####|Target Group|####
######################
# App TG
resource "aws_lb_target_group" "app_tg" {
    name     = "app-tier-tg"
    port     = 4000
    protocol = "HTTP"
    vpc_id   = aws_vpc.sankar.id

    health_check {
    path     = "/health"
    protocol = "HTTP"
    }
}

# Web TG
resource "aws_lb_target_group" "web_tg" {
    name     = "web-tier-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.sankar.id

    health_check {
    path     = "/health"
    protocol = "HTTP"
    }
}

#####################
########|ALB|########
#####################
# Internal APP ALB
    resource "aws_lb" "app_alb" {
    name               = "app-internal-alb"
    internal           = true
    load_balancer_type = "application"
    security_groups    = [aws_security_group.ILB.id]
    subnets            = [aws_subnet.pvt-sub1.id, aws_subnet.pvt-sub2.id]
}

resource "aws_lb_listener" "app_listener" {
    load_balancer_arn = aws_lb.app_alb.arn
    port              = "4000"
    protocol          = "HTTP"

    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
    }
}

# External WEB ALB
resource "aws_lb" "web_alb" {
    name               = "external-web-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.ELB.id]
    subnets            = [aws_subnet.pub-sub1.id, aws_subnet.pub-sub2.id]
}

resource "aws_lb_listener" "web_listener" {
    load_balancer_arn = aws_lb.web_alb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
    }
}

#######################
###|Launch Template|###
#######################
# App LT
resource "aws_launch_template" "app_lt" {
    name_prefix   = "app-tier-"
    image_id      = var.ami
    instance_type = var.instance_type
    key_name      = var.key_pari
    vpc_security_group_ids = [aws_security_group.app-server.id]

    user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    # install Node.js + app setup here
    EOF
    )
    }

# Web LT
resource "aws_launch_template" "web_lt" {
    name_prefix   = "web-tier-"
    image_id      = var.ami
    instance_type = var.instance_type
    key_name      = var.key_pari
    vpc_security_group_ids = [aws_security_group.web-server.id]

    user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl enable nginx
    systemctl start nginx
    EOF
    )
}

######################
#|Auto Scaling Group|#
######################
# App ASG
    resource "aws_autoscaling_group" "app_asg" {
    name                = "app-tier-asg"
    vpc_zone_identifier = [aws_subnet.pvt-sub1.id, aws_subnet.pvt-sub2.id]
    desired_capacity    = 2
    min_size            = 1
    max_size            = 4

    launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
    }

    target_group_arns = [aws_lb_target_group.app_tg.arn]
}

# Web ASG
    resource "aws_autoscaling_group" "web_asg" {
    name                = "web-tier-asg"
    vpc_zone_identifier = [aws_subnet.pub-sub1.id, aws_subnet.pub-sub2.id]
    desired_capacity    = 2
    min_size            = 1
    max_size            = 4

    launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
    }

    target_group_arns = [aws_lb_target_group.web_tg.arn]
}
