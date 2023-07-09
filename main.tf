

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
