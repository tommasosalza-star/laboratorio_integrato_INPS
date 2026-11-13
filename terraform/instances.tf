resource "aws_instance" "juiceshop" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_types.juiceshop
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.juiceshop.id]
  iam_instance_profile        = "LabInstanceProfile"
  key_name                    = var.key_name
  associate_public_ip_address = false
  monitoring                  = true

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    apt-get update
    apt-get install -y ca-certificates curl docker.io
    systemctl enable --now docker
    docker run -d --restart unless-stopped --name juiceshop -p 3000:3000 bkimminich/juice-shop:latest
  EOF

  tags = {
    Name = "${var.project_name}-juiceshop"
    Role = "juiceshop"
  }
}

resource "aws_instance" "waf" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_types.waf
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.waf.id]
  iam_instance_profile        = "LabInstanceProfile"
  key_name                    = var.key_name
  associate_public_ip_address = true
  monitoring                  = true

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  depends_on = [aws_instance.juiceshop]

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    apt-get update
    apt-get install -y nginx libnginx-mod-http-modsecurity
    cat >/etc/nginx/sites-available/default <<'NGINX'
    server {
      listen 80 default_server;
      location / {
        proxy_pass http://${aws_instance.juiceshop.private_ip}:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      }
    }
    NGINX
    nginx -t
    systemctl enable nginx
    systemctl restart nginx
  EOF

  tags = {
    Name = "${var.project_name}-waf"
    Role = "waf"
  }
}

resource "aws_instance" "siem" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_types.siem
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.siem.id]
  iam_instance_profile        = "LabInstanceProfile"
  key_name                    = var.key_name
  associate_public_ip_address = false
  monitoring                  = true

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size = 60
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    apt-get update
    apt-get install -y curl
    curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
    bash wazuh-install.sh -a
  EOF

  tags = {
    Name = "${var.project_name}-siem"
    Role = "siem-wazuh"
  }
}
