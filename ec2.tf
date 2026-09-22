# ==============================
# Amazon Linux 2023 AMI
# ==============================

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ==============================
# IAM Role for SSM
# ==============================

resource "aws_iam_role" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm.name
}

# ==============================
# EC2 - AZ 1a
# ==============================

resource "aws_instance" "web_1a" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.app_1a.id
  vpc_security_group_ids = [aws_security_group.app.id]

  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  depends_on = [
    aws_route_table_association.app_1a
  ]

  user_data = <<-EOF_USER_DATA
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd

    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>HA Web Infrastructure</title>
    </head>
    <body>
      <h1>HA Web Infrastructure</h1>
      <p>Server: web-1a</p>
      <p>Availability Zone: ap-northeast-1a</p>
    </body>
    </html>
    HTML
  EOF_USER_DATA

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "${var.project_name}-web-1a"
  }
}

# ==============================
# EC2 - AZ 1c
# ==============================

resource "aws_instance" "web_1c" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.app_1c.id
  vpc_security_group_ids = [aws_security_group.app.id]

  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  depends_on = [
    aws_route_table_association.app_1c
  ]

  user_data = <<-EOF_USER_DATA
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd

    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>HA Web Infrastructure</title>
    </head>
    <body>
      <h1>HA Web Infrastructure</h1>
      <p>Server: web-1c</p>
      <p>Availability Zone: ap-northeast-1c</p>
    </body>
    </html>
    HTML
  EOF_USER_DATA

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "${var.project_name}-web-1c"
  }
}

# ==============================
# Target Group Attachments
# ==============================

resource "aws_lb_target_group_attachment" "web_1a" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_1c" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_1c.id
  port             = 80
}
