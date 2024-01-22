resource "aws_vpc" "stark" {
  cidr_block         = var.vpc_cidr

  tags   = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "subnets" {
  count              = length(var.subnet_tags)
  vpc_id             = aws_vpc.stark.id
  cidr_block         = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone  = var.az_zones[count.index]

  tags               = {
    Name             = var.subnet_tags[count.index]
  }
  depends_on = [ aws_vpc.stark ]
}

resource "aws_internet_gateway" "igateway" {
  vpc_id             = aws_vpc.stark.id

  tags               = {
    Name             = "IGW"
  }
  depends_on = [ aws_vpc.stark, aws_subnet.subnets ]
}

resource "aws_security_group" "Web-SG" {
  vpc_id             = aws_vpc.stark.id
  description        = local.default_desc

  ingress {
    from_port        = local.ssh_port
    to_port          = local.ssh_port
    protocol         = local.protocol
    cidr_blocks      = [local.any_where]
  }

  ingress {
    from_port        = local.http_port
    to_port          = local.http_port
    protocol         = local.protocol
    cidr_blocks      = [local.any_where]
  }

  egress {
    from_port        = local.all_ports
    to_port          = local.all_ports
    protocol         = local.any_protocol
    cidr_blocks      = [local.any_where]
    ipv6_cidr_blocks = [local.any_where_ipv6]
  }

  tags               = {
    Name             = "Web Security"
  }
  depends_on = [ aws_vpc.stark ]

}

resource "aws_route_table" "public_rt" {
  vpc_id             = aws_vpc.stark.id

  route {
    cidr_block       = local.any_where
    gateway_id       = aws_internet_gateway.igateway.id
  }

    tags               = {
    Name             = "Public RT"
  }
  depends_on = [ aws_internet_gateway.igateway ]

}

resource "aws_route_table" "private_rt" {
  vpc_id             = aws_vpc.stark.id

  tags               = {
    Name             = "Private RT"
  }
  depends_on = [ aws_internet_gateway.igateway ]

}

resource "aws_route_table_association" "a" {
  count          = length(var.subnet_tags)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = contains(var.public_routes, lookup(aws_subnet.subnets[count.index].tags_all, "Name", "")) ? aws_route_table.public_rt.id: aws_route_table.private_rt.id
                  #count.index<2 ? aws_route_table.public_rt.id: aws_route_table.private_rt.id
  
  depends_on = [ aws_route_table.public_rt, aws_route_table.private_rt ]
}


# resource "aws_security_group" "App_SG" {
#   vpc_id             = aws_vpc.stark.id
#   description        = local.default_desc

#   ingress {
#     from_port        = local.ssh_port
#     to_port          = local.ssh_port
#     protocol         = local.protocol
#     cidr_blocks      = [local.any_where]
#   }  

#   ingress {
#     from_port        = local.app_port
#     to_port          = local.app_port
#     protocol         = local.protocol
#     cidr_blocks      = [var.vpc_cidr]
#   }

#   egress {
#     from_port        = local.all_ports
#     to_port          = local.all_ports
#     protocol         = local.any_protocol
#     cidr_blocks      = [local.any_where]
#     ipv6_cidr_blocks = [local.any_where_ipv6]
#   }
  
#   tags               = {
#     Name             = "App Security"
#   }
#   depends_on = [ aws_vpc.stark ]
# }


# resource "aws_security_group" "db_SG" {
#   vpc_id             = aws_vpc.stark.id
#   description        = local.default_desc

#   ingress {
#     from_port        = local.ssh_port
#     to_port          = local.ssh_port
#     protocol         = local.protocol
#     cidr_blocks      = [local.any_where]
#   }  

#   ingress {
#     from_port        = local.db_port
#     to_port          = local.db_port
#     protocol         = local.protocol
#     cidr_blocks      = [var.vpc_cidr]
#   }

#   egress {
#     from_port        = local.all_ports
#     to_port          = local.all_ports
#     protocol         = local.any_protocol
#     cidr_blocks      = [local.any_where]
#     ipv6_cidr_blocks = [local.any_where_ipv6]
#   }
  
#   tags               = {
#     Name             = "DB Security"
#   }
#   depends_on = [ aws_vpc.stark ]

# }

