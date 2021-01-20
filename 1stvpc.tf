provider "aws" {
  alias = "us-west-2"
  access_key = "AKIAZYBNCDOFND3OZAIG"
  secret_key = "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"
  region     = "us-west-2"
}

#VPC creation
resource "aws_vpc" "Bastion_VPC" {
  cidr_block       = "10.0.0.0/26"
  instance_tenancy = "default"
   #enable_dns_support = “true” #gives you an internal domain name
   # enable_dns_hostnames = “true” #gives you an internal host name
   # enable_classiclink = “false”
   # instance_tenancy = “default”

  tags = {
    Name = "Bastion_VPC"
  }
}

# Custom Route table creation
resource "aws_route_table" "Bastion_VPC_rt" {
  vpc_id = aws_vpc.Bastion_VPC.id

  tags = {
    Name = "Bastion_VPC_rt"
  }
}


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
  map_public_ip_on_launch = "false" //it makes this a public subnet
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

#Creation of Nat Gateway
/*resource "aws_nat_gateway" "Bastion_ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.Public_Subnet.id

  tags = {
    Name = "Bastion_ngw"
  }
}
*/

resource "aws_security_group" "ssh-allowed" {
    vpc_id = aws_vpc.Bastion_VPC.id
    
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
    /*tags {
        Name = "ssh-allowed"
    }*/
}

# Public Instance Creation
resource "aws_instance" "Public-subnet_1a" {
  ami           = "ami-04b1ddd35fd71475a"
  instance_type = "t2.micro"
  vpc_id        = aws_vpc.Bastion_VPC.id
  subnet_id     = aws_subnet.Public_Subnet.id
  vpc_security_group_ids = aws_security_group.ssh-allowed.id
  region     = "ap-south-1"
  /*user_data     = <<-EOF
                  #!/bin/bash
                  sudo su
                  yum -y install httpd
                  echo "<p> My Instance! </p>" >> /var/www/html/index.html
                  sudo systemctl enable httpd
                  sudo systemctl start httpd
                  EOF
  */

  tags = {
    Name = "Public-subnet_1a"
  }
}

# Key Pair Creation
resource "aws_key_pair" "Bastion" {
  key_name   = "Bastion-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAssQ4Z7QC7xAbPzhIGlJ+xX45GG5dugE1mCoVAWFBh+5hZSQUiPHb3d/dQmt/RLS3+NdTYjz9x5Htn7eBgQ1cPYs94Ol62rRCnR4z/74XMzgFwlwQzOEpxxBO6jqFnaTFtDgutpQxDVCkXv+sGM8TeiSwLIJzkKSJTWnqr/aVmdXNRIoHN2DvamEBUxrz9F+ZC9mvgvV6SaMQR/Oa6sAIXZpWPiF3s5iZuflU5JEPwMn7dFmQgyPvKLQCtZR3eGQ/FQrbIUb1/mf4KWoNVsFUdIx/mbZiHDHVj4XI5k7NbNqdVq3oUjxMJWLYBv+JkRTCmzceBolLciIoYaSb/uydBQ=="
}