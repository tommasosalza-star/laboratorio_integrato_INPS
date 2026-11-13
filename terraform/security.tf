resource "aws_security_group" "waf" {
  name        = "${var.project_name}-waf"
  description = "Public web access and administration for the WAF"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "siem" {
  name        = "${var.project_name}-siem"
  description = "Wazuh manager and administration"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description     = "SSH from WAF bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.waf.id]
  }

  ingress {
    description     = "Wazuh dashboard from the WAF host"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.waf.id]
  }

  ingress {
    description = "Wazuh agent enrollment"
    from_port   = 1515
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lab.cidr_block]
  }

  ingress {
    description = "Wazuh agent events"
    from_port   = 1514
    to_port     = 1514
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lab.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "juiceshop" {
  name        = "${var.project_name}-juiceshop"
  description = "Juice Shop application, reachable through the WAF"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description     = "Juice Shop through the WAF"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.waf.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
