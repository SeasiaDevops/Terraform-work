#VPC creation
resource "aws_vpc" "Bastion_VPC" {
  cidr_block       = "10.0.0.0/26"
  instance_tenancy = "default"
   enable_dns_support = "true" #gives you an internal domain name
   enable_dns_hostnames = "true" #gives you an internal host name
   # enable_classiclink = “false”
   # instance_tenancy = “default”

  tags = {
    Name = "Bastion_VPC"
  }
}

# Custom(Private) Route table creation
resource "aws_route_table" "Bastion_VPC_rt_private" {
  vpc_id = aws_vpc.Bastion_VPC.id

  tags = {
    Name = "Bastion_VPC_rt_private"
  }
}

#Custom(Private) Route Table Subnet Association
resource "aws_route_table_association" "Pvt" {
  subnet_id      = aws_subnet.Private_Subnet.id
  route_table_id = aws_route_table.Bastion_VPC_rt_private.id
}


# Custom(Public) Route table creation
resource "aws_route_table" "Bastion_VPC_rt_pub" {
  vpc_id = aws_vpc.Bastion_VPC.id

  tags = {
    Name = "Bastion_VPC_rt_pub"
  }
}

#Custom(Public) Route Table Subnet Association
resource "aws_route_table_association" "Pub" {
  subnet_id      = aws_subnet.Public_Subnet.id
  route_table_id = aws_route_table.Bastion_VPC_rt_pub.id
}

# Default(Public) Route Table Tag Created
/*resource "aws_default_route_table" "Bastion_VPC_rt_Public" {
  default_route_table_id = aws_vpc.Bastion_VPC.default_route_table_id

  route {
    # ...
  }
  

  tags = {
    Name = "Bastion_VPC_rt_Public"
  }
}
*/

/*#Public Route-Table Subnet Association
resource "aws_main_route_table_association" "Pub" {
  vpc_id         = aws_vpc.Bastion_VPC.id
  route_table_id = aws_route_table.Bastion_VPC_rt_Public.id
}*/


#Public Subnet Creation
resource "aws_subnet" "Public_Subnet" {
  vpc_id     = aws_vpc.Bastion_VPC.id
  cidr_block = "10.0.0.0/27"
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Public_Subnet"
  }
}

#Private Subnet Creation
resource "aws_subnet" "Private_Subnet" {
  vpc_id     = aws_vpc.Bastion_VPC.id
  cidr_block = "10.0.0.32/27"
  map_public_ip_on_launch = "false" //it makes this a private subnet
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Private_Subnet"
  }
}

# Creation of internet Gateway
resource "aws_internet_gateway" "Bastion_gw" {
  vpc_id = aws_vpc.Bastion_VPC.id

  tags = {
    Name = "Bastion_gw"
  }
}

#Internet Gateway(IGW) Adding to Route Table
resource "aws_route" "public-internet-gw-route" {
    route_table_id = aws_route_table.Bastion_VPC_rt_pub.id
    gateway_id = aws_internet_gateway.Bastion_gw.id
    destination_cidr_block = "0.0.0.0/0"
}

# Creating An Elastic IP for NAT Gateway.
resource "aws_eip" "elastic-ip-for-nat-gw" {
    vpc = true
    associate_with_private_ip = "10.0.0.5"
        tags = {
            Name = "elastic-ip-for-nat-gw"
            }
}
#Creation of Nat Gateway
resource "aws_nat_gateway" "Bastion_ngw" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw.id
  subnet_id     = aws_subnet.Public_Subnet.id

  tags = {
    Name = "Bastion_ngw"
  }
}

#NAT Gateway(NGW) Adding to Route Table
resource "aws_route" "private-ngw-route" {
    route_table_id = aws_route_table.Bastion_VPC_rt_private.id
    nat_gateway_id = aws_nat_gateway.Bastion_ngw.id
    destination_cidr_block = "0.0.0.0/0"
}

#Security Group
resource "aws_security_group" "Bastion_testing" {
    vpc_id = aws_vpc.Bastion_VPC.id
    name = "Bastion_testing"
    description = "Allow SSH and HTTP"

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        // This means, all ip address are allowed to ssh ! 
        // Do not do it in the production. 
        // Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }
    //If you do not add this rule, you can not reach the APACHE  
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
    Name = "newTesting"
  }
    
}


# Public Instance Creation
resource "aws_instance" "Public-subnet_1a" {
  ami           = "ami-04b1ddd35fd71475a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.Public_Subnet.id
  key_name      = "autoscaling"
  vpc_security_group_ids = [aws_security_group.Bastion_testing.id]
    user_data     = <<-EOF
                  #!/bin/bash
                  sudo su
                  yum -y install httpd
                  echo "<p> This is the Amazon Linux 2 AMI (HVM) with Public-subnet-1a and Apache webServer is installed on it! </p>" >> /var/www/html/index.html
                  sudo systemctl enable httpd
                  sudo systemctl start httpd
                  EOF


  tags = {
    Name = "Public-subnet_1a"
  }
}

#Security Group for Private Instance
/*resource "aws_security_group" "db" {
    name = "vpc_db"
    description = "Allow incoming database connections."
    ingress { # MySQL
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        #cidr_blocks = ["0.0.0.0/0"]
        security_groups = ["${aws_security_group.web.id}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
   
    
    egress {
    description = "output"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
*/

# Private Instance Creation
resource "aws_instance" "Private-subnet_1a" {
  ami           = "ami-0db0b3ab7df22e366"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.Private_Subnet.id
  key_name   = "autoscaling"
  vpc_security_group_ids = [aws_security_group.Bastion_testing.id]
    user_data     = <<-EOF
                  #!/bin/bash
                  sudo apt update 
                  sudo apt install -y mysql-server
                  sudo mysql_secure_installation -y
                  EOF
    
  tags = {
    Name = "Private-subnet_1a"
  }
}

## Key Pair Creation
#resource "aws_key_pair" "Bastion" {
  
 # key_name   = "Bastion-key"
 # public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAg7f7p8CC6JqQwjOAGQImRmq0Ra5fXRIVNqD1E5V7RcoMGd7FgJw8Rs9ZGP9CmuN4U+NqZpbqxftIs5Vk/zQ9aoAfVmGspMg8Clw8UJCiboJl+bNIoouv0RI6vW4tOYy087GWaItBvp8k91e/sPjoOaIEv1hmFV/mHwAITrlI7Aq3M4sp9bvP25fqnapxhscINfXFQ6FIjxmkL4UVLN7MVokbpPAzsjv5+p/N6x2q/FPxxqDX7THZAgjRy2hSJbGR8/n61HfKVS7LtQ2oPTz0bzoop4tEs2tz/bM13tR65x2FfOsP3Gy4AD18NoEwnomVOS4X9j702xCf6AYALCniAQ=="
# }