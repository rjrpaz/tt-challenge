# --- compute/main.tf ---

data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]
  # owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  # filter {
  #   name   = "name"
  #   values = ["amzn2-ami-kernel-5.10-hvm-2.0.*"]
  # }
}

resource "aws_key_pair" "tt_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Frontend configuration template
resource "aws_launch_configuration" "tt-lc-front" {
  name_prefix   = "tt-lc-asg-front-"
  image_id      = data.aws_ami.server_ami.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.tt_auth.id
  # user_data     = file("install_frontend.sh")
  user_data = <<EOF
#!/bin/bash

# Install npm
sudo apt -y update
sudo apt -y install npm

# Clone project
cd /home/ubuntu
git clone https://rjrpaz:${var.gitlab_token}@git.toptal.com/rjrpaz/node-3tier-app2.git node-3tier-app2

# Install node required dependencies
cd /home/ubuntu/node-3tier-app2/web

npm install

# Configure app as a service for the OS
sudo tee -a /etc/systemd/system/nodefront.service > /dev/null <<EOT
[Unit]
Description=frontend for the nodeapp service

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/node-3tier-app2/web
Environment=PORT=8080
Environment=API_HOST=http://${var.apiendpoint}
ExecStart=npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload

# Enable and start the app
sudo systemctl enable --now nodefront.service
EOF

  security_groups = [var.private_sg_front]

  lifecycle {
    create_before_destroy = true
  }
}

# Frontend autoscaling group
resource "aws_autoscaling_group" "asg_front" {
  name = "tt-front"
  min_size = var.min_size
  max_size = var.max_size
  desired_capacity     = var.desired_capacity
  launch_configuration = aws_launch_configuration.tt-lc-front.name
  vpc_zone_identifier = var.private_subnets_front
  target_group_arns   = var.lb_target_group_front_arn
}

# Backend configuration template
resource "aws_launch_configuration" "tt-lc-back" {
  name_prefix   = "tt-lc-asg-back-"
  image_id      = data.aws_ami.server_ami.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.tt_auth.id
  # user_data     = file("install_backend.sh")
  user_data = <<EOF
#!/bin/bash

# Install npm
sudo apt -y update
sudo apt -y install npm

# Clone project
cd /home/ubuntu
git clone https://rjrpaz:${var.gitlab_token}@git.toptal.com/rjrpaz/node-3tier-app2.git node-3tier-app2

# Install node required dependencies
cd /home/ubuntu/node-3tier-app2/api

npm install

# Configure app as a service for the OS
sudo tee -a /etc/systemd/system/nodeback.service > /dev/null <<EOT
[Unit]
Description=backend for the nodeapp service

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/node-3tier-app2/api
Environment=PORT=8081
Environment=DB=${var.dbname}
Environment=DBUSER=${var.dbuser}
Environment=DBPASS=${var.dbpass}
Environment=DBHOST=${var.dbhost}
Environment=DBPORT=${var.dbport}
ExecStart=npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload

# Enable and start the app
sudo systemctl enable --now nodeback.service
EOF
  security_groups = [var.private_sg_back]

  lifecycle {
    create_before_destroy = true
  }
}

# Backend autosacaling group
resource "aws_autoscaling_group" "asg_back" {
  name = "tt-back"
  min_size = var.min_size
  max_size = var.max_size
  desired_capacity     = var.desired_capacity
  launch_configuration = aws_launch_configuration.tt-lc-back.name
  vpc_zone_identifier = var.private_subnets_back
  target_group_arns   = var.lb_target_group_back_arn
}

# Bastion host - for debug purposes only
resource "aws_instance" "bastion" {
  count         = var.create_bastion ? 1 : 0
  instance_type = var.instance_type
  ami           = data.aws_ami.server_ami.id
  tags = {
    Name = "tt-bastion"
  }

  key_name               = aws_key_pair.tt_auth.id
  vpc_security_group_ids = [var.public_sg_front]
  subnet_id              = var.public_subnets_front[count.index]

  user_data = <<EOF
#!/bin/bash
echo "${file(var.private_key_path)}" | sudo tee /home/ubuntu/.ssh/id_rsa
echo "${file(var.public_key_path)}" | sudo tee /home/ubuntu/.ssh/id_rsa.pub
chmod 600 /home/ubuntu/.ssh/id_rsa
chmod 644 /home/ubuntu/.ssh/id_rsa.pub
chown ubuntu.ubuntu /home/ubuntu/.ssh/id_rsa
chown ubuntu.ubuntu /home/ubuntu/.ssh/id_rsa.pub
EOF

}
