
#Configure AWS Provider
#Operational environment is set to run in <us-east-1> region

resource "aws_s3_bucket" "b2" {
  bucket = "thisismybucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b2.id
  acl    = "private"
}


resource "aws_security_group" "allow_tls_second" {
  name        = "allow_tls_second"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
  }
}



#Configure custom VPC
resource "aws_vpc" "TF_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "TF_vpc"
    }
}

#Configure internet gateway
resource "aws_internet_gateway" "TF_gw" {
    vpc_id = aws_vpc.TF_vpc.id

    tags = {
        Name = "TF_gw"
    }
}

#Configure custom route table
resource "aws_route_table" "TF-rte-tble" {
    vpc_id = aws_vpc.TF_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.TF_gw.id
    }

      route {
        ipv6_cidr_block        = "::/0"
        gateway_id = aws_internet_gateway.TF_gw.id
    }

    tags = {
        Name = "TF-route"
    }
}

#Configure subnet for us-east-1a
resource "aws_subnet" "TF_subnet_1a" {
    vpc_id = aws_vpc.TF_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        ame = "TF_subnet"
    }
}

#Configure subnet for us-east-1b
resource "aws_subnet" "TF_subnet_1b" {
    vpc_id = aws_vpc.TF_vpc.id
    cidr_block = "10.0.10.0/24"
    availability_zone = "us-east-1b"

    tags = {
        ame = "TF_subnet"
    }
}

#Configure route table with subnet 1a
resource "aws_route_table_association" "TF_sub_ass_1a" {
    subnet_id      = aws_subnet.TF_subnet_1a.id
    route_table_id = aws_route_table.TF-rte-tble.id
}

#Configure route table with subnet 1b
resource "aws_route_table_association" "TF_sub_ass_1b" {
    subnet_id      = aws_subnet.TF_subnet_1b.id
    route_table_id = aws_route_table.TF-rte-tble.id
}

#Configure network interface for AmazonLinux
resource "aws_network_interface" "TF_NIC_AMZN_LX" {
    subnet_id       = aws_subnet.TF_subnet_1a.id
    private_ips     = ["10.0.1.50"]
    security_groups = [aws_security_group.TF_allow_web.id]

    tags = {
        Name = "TF_NIC_AMZN_LX"
    }
}

#Configure network interface for Ubuntu
resource "aws_network_interface" "TF_NIC_UBUNTU" {
    subnet_id       = aws_subnet.TF_subnet_1b.id
    private_ips     = ["10.0.10.51"]
    security_groups = [aws_security_group.TF_allow_web.id]

    tags = {
        Name = "TF_NIC_UBUNTU"
    }
}

#Create AWS Elastic IP for AmazonLinux
resource "aws_eip" "TF_EIP_1" {
    vpc                       = true
    network_interface         = aws_network_interface.TF_NIC_AMZN_LX.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.TF_gw]
}

#Create AWS Elastic IP for Ubuntu
resource "aws_eip" "TF_EIP_2" {
    vpc                       = true
    network_interface         = aws_network_interface.TF_NIC_UBUNTU.id
    associate_with_private_ip = "10.0.10.51"
    depends_on = [aws_internet_gateway.TF_gw]
}

#Create security group for instances
resource "aws_security_group" "TF_allow_web" {
    name        = "allow_elb_traffic"
    description = "Allow LB inbound traffic"
    vpc_id      = aws_vpc.TF_vpc.id

    #Inbound HTTP




    ingress {
        description      = "HTTP from VPC"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        security_groups = [aws_security_group.TF_ELB_SG.id]
    }

    #Inbound HTTPS
    ingress {
        description      = "HTTPs from VPC"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    #Inbound SSH
    ingress {
        description      = "SSH from VPC"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    #Outbound ANY
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "TF_Allow_Web"
    }
}

#Create security group for Elastic Load Balancer
resource "aws_security_group" "TF_ELB_SG" {
    name        = "allow_web_traffic"
    description = "Allow Web inbound traffic"
    vpc_id      = aws_vpc.TF_vpc.id

    #Inbound HTTP
    ingress {
        description      = "HTTP from VPC"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        
    }

    #Inbound HTTPS
    ingress {
        description      = "HTTPs from VPC"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    #Inbound SSH
    ingress {
        description      = "SSH from VPC"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    #Outbound ANY
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "TF_ELB_SG"
    }
}


#Linux environment configuration

#Install and configure Apache web server on AmazonLinux
#Deployed on /us-east-1a/
resource "aws_instance" "myFirst_TF-server" {
    ami           = "ami-0d5eff06f840b45e9"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "enterhere"
    user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum upgrade -y
        yum install -y httpd.x86_64
        systemctl start httpd.service
        systemctl enable httpd.service
        echo "Hello this is terraform made Amazon_Linux server from $(hostname -f)" > /var/www/html/index.html
        EOF

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.TF_NIC_AMZN_LX.id
    }

  tags = {
    Name = "TF_AmazonLinux_web"
  }
}



#Install and configure Apache web server on Ubuntu
#Deployed on /us-east-1b/
resource "aws_instance" "mySecond_TF-server" {
    ami           = "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    availability_zone = "us-east-1b"
    key_name = "enterhere"
    user_data = <<-EOF
        #!/bin/bash
        sudo apt-get update -y
        sudo apt-get install -y apache2
        sudo systemctl start apache2
        echo "Hello this is terraform made Ubuntu server from $(hostname -f)" > /var/www/html/index.html
        EOF

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.TF_NIC_UBUNTU.id
    }

  tags = {
    Name = "TF_Ubuntu_web"
  }
}

resource "aws_elb" "my-elb" {
    name               = "my-elb"
    subnets = [aws_subnet.TF_subnet_1a.id, aws_subnet.TF_subnet_1b.id]
    security_groups = [aws_security_group.TF_ELB_SG.id]

    listener {
        instance_port     = 80
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }

    health_check {
        healthy_threshold   = 10
        unhealthy_threshold = 2
        timeout             = 5
        target              = "HTTP:80/"
        interval            = 10
    }

    instances                   = [aws_instance.myFirst_TF-server.id, aws_instance.mySecond_TF-server.id]
    cross_zone_load_balancing   = true
    idle_timeout                = 400
    connection_draining         = true
    connection_draining_timeout = 400

    tags = {
        Name = "my-elb"
    }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_default_vpc.default.id
  cidr_block = "172.2.0.0/16"
}

resource "aws_subnet" "in_secondary_cidr" {
  vpc_id     = aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id
  cidr_block = "172.2.0.0/24"
}

