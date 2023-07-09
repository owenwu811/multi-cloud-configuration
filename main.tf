
resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
#importing infrastructure into terraform's control
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "web2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "ec2"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "azurerm_resource_group" "dbresource" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_mysql_server" "example" {
  name                = "sqlserverowen"
  location            = azurerm_resource_group.dbresource.location
  resource_group_name = azurerm_resource_group.dbresource.name
  
  administrator_login          = "mysqladminun"
  administrator_login_password = "H@Sh1CoR3!"

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
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

resource "azurerm_resource_group" "LBresource" {
  name     = "LoadBalancerRG"
  location = "West Europe"
}

resource "azurerm_public_ip" "example" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.LBresource.location
  resource_group_name = azurerm_resource_group.LBresource.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "testLB" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.LBresource.location
  resource_group_name = azurerm_resource_group.LBresource.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}
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

resource "azurerm_resource_group" "example2" {
  name     = "example-resources2"
  location = "West Europe"
}

resource "azurerm_network_security_group" "example" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

#Configure AWS Provider
#Operational environment is set to run in <us-east-1> region


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
