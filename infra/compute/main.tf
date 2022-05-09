# --- compute/main.tf ---

data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "tt_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Frontend configuration template
resource "aws_launch_configuration" "tt_lc_front" {
  name_prefix          = "tt-lc-asg-front-"
  image_id             = data.aws_ami.server_ami.id
  instance_type        = var.instance_type
  iam_instance_profile = var.instance_profile
  enable_monitoring    = true
  key_name             = aws_key_pair.tt_auth.id
  # user_data     = file("install_frontend.sh")
  user_data = <<EOF
#!/bin/bash

# Install npm
sudo apt -y update
sudo apt -y install npm

# Install cloudwatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
sudo dpkg -i -E /tmp/amazon-cloudwatch-agent.deb

sudo tee -a /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOT
    {
      "agent": {
        "metrics_collection_interval": 10,
        "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
      },
      "metrics": {
        "namespace": "MyCustomNamespace",
        "metrics_collected": {
          "cpu": {
            "resources": [
              "*"
            ],
            "measurement": [
              {"name": "cpu_usage_idle", "rename": "CPU_USAGE_IDLE", "unit": "Percent"},
              {"name": "cpu_usage_nice", "unit": "Percent"},
              "cpu_usage_guest"
            ],
            "totalcpu": false,
            "metrics_collection_interval": 10,
            "append_dimensions": {
              "customized_dimension_key_1": "customized_dimension_value_1",
              "customized_dimension_key_2": "customized_dimension_value_2"
            }
          },
          "disk": {
            "resources": [
              "/",
              "/tmp"
            ],
            "measurement": [
              {"name": "free", "rename": "DISK_FREE", "unit": "Gigabytes"},
              "total",
              "used"
            ],
             "ignore_file_system_types": [
              "sysfs", "devtmpfs"
            ],
            "metrics_collection_interval": 60,
            "append_dimensions": {
              "customized_dimension_key_3": "customized_dimension_value_3",
              "customized_dimension_key_4": "customized_dimension_value_4"
            }
          },
          "diskio": {
            "resources": [
              "*"
            ],
            "measurement": [
              "reads",
              "writes",
              "read_time",
              "write_time",
              "io_time"
            ],
            "metrics_collection_interval": 60
          },
          "swap": {
            "measurement": [
              "swap_used",
              "swap_free",
              "swap_used_percent"
            ]
          },
          "mem": {
            "measurement": [
              "mem_used",
              "mem_cached",
              "mem_total"
            ],
            "metrics_collection_interval": 1
          },
          "net": {
            "resources": [
              "eth0"
            ],
            "measurement": [
              "bytes_sent",
              "bytes_recv",
              "drop_in",
              "drop_out"
            ]
          },
          "netstat": {
            "measurement": [
              "tcp_established",
              "tcp_syn_sent",
              "tcp_close"
            ],
            "metrics_collection_interval": 60
          },
          "processes": {
            "measurement": [
              "running",
              "sleeping",
              "dead"
            ]
          }
        },
        "append_dimensions": {
          "ImageId": "\$${aws:ImageId}",
          "InstanceId": "\$${aws:InstanceId}",
          "InstanceType": "\$${aws:InstanceType}",
          "AutoScalingGroupName": "\$${aws:AutoScalingGroupName}"
        },
        "aggregation_dimensions" : [["ImageId"], ["InstanceId", "InstanceType"], ["d1"],[]],
        "force_flush_interval" : 30
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
                "log_group_name": "amazon-cloudwatch-agent.log",
                "log_stream_name": "amazon-cloudwatch-agent.log",
                "timezone": "UTC"
              },
              {
                "file_path": "/var/log/syslog",
                "log_group_name": "messages.log",
                "log_stream_name": "messages.log",
                "timezone": "Local"
              },
              {
                "file_path": "/home/ubuntu/app.log",
                "log_group_name": "app.log",
                "log_stream_name": "app.log",
                "timezone": "UTC"
              },
              {
                "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/test.log",
                "log_group_name": "test.log",
                "log_stream_name": "test.log",
                "timezone": "Local"
              }
            ]
          }
        },
        "log_stream_name": "my_log_stream_name",
        "force_flush_interval" : 15
      }
    }
EOT

sudo systemctl enable --now amazon-cloudwatch-agent

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
StandardOutput=file:/home/ubuntu/app.log
StandardError=file:/home/ubuntu/app.log
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

data "aws_default_tags" "asg_front" {
  tags = {
    Name = "tt-front"
  }
}

# Frontend autoscaling group
resource "aws_autoscaling_group" "asg_front" {
  name                 = "tt-front"
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  launch_configuration = aws_launch_configuration.tt_lc_front.name
  vpc_zone_identifier  = var.private_subnets_front
  target_group_arns    = var.lb_target_group_front_arn
  dynamic "tag" {
    for_each = data.aws_default_tags.asg_front.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Backend configuration template
resource "aws_launch_configuration" "tt_lc_back" {
  name_prefix          = "tt-lc-asg-back-"
  image_id             = data.aws_ami.server_ami.id
  instance_type        = var.instance_type
  iam_instance_profile = var.instance_profile
  enable_monitoring    = true
  key_name             = aws_key_pair.tt_auth.id
  # user_data     = file("install_backend.sh")
  user_data       = <<EOF
#!/bin/bash

# Install npm
sudo apt -y update
sudo apt -y install npm


# Install cloudwatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
sudo dpkg -i -E /tmp/amazon-cloudwatch-agent.deb

sudo tee -a /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOT
    {
      "agent": {
        "metrics_collection_interval": 10,
        "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
      },
      "metrics": {
        "namespace": "MyCustomNamespace",
        "metrics_collected": {
          "cpu": {
            "resources": [
              "*"
            ],
            "measurement": [
              {"name": "cpu_usage_idle", "rename": "CPU_USAGE_IDLE", "unit": "Percent"},
              {"name": "cpu_usage_nice", "unit": "Percent"},
              "cpu_usage_guest"
            ],
            "totalcpu": false,
            "metrics_collection_interval": 10,
            "append_dimensions": {
              "customized_dimension_key_1": "customized_dimension_value_1",
              "customized_dimension_key_2": "customized_dimension_value_2"
            }
          },
          "disk": {
            "resources": [
              "/",
              "/tmp"
            ],
            "measurement": [
              {"name": "free", "rename": "DISK_FREE", "unit": "Gigabytes"},
              "total",
              "used"
            ],
             "ignore_file_system_types": [
              "sysfs", "devtmpfs"
            ],
            "metrics_collection_interval": 60,
            "append_dimensions": {
              "customized_dimension_key_3": "customized_dimension_value_3",
              "customized_dimension_key_4": "customized_dimension_value_4"
            }
          },
          "diskio": {
            "resources": [
              "*"
            ],
            "measurement": [
              "reads",
              "writes",
              "read_time",
              "write_time",
              "io_time"
            ],
            "metrics_collection_interval": 60
          },
          "swap": {
            "measurement": [
              "swap_used",
              "swap_free",
              "swap_used_percent"
            ]
          },
          "mem": {
            "measurement": [
              "mem_used",
              "mem_cached",
              "mem_total"
            ],
            "metrics_collection_interval": 1
          },
          "net": {
            "resources": [
              "eth0"
            ],
            "measurement": [
              "bytes_sent",
              "bytes_recv",
              "drop_in",
              "drop_out"
            ]
          },
          "netstat": {
            "measurement": [
              "tcp_established",
              "tcp_syn_sent",
              "tcp_close"
            ],
            "metrics_collection_interval": 60
          },
          "processes": {
            "measurement": [
              "running",
              "sleeping",
              "dead"
            ]
          }
        },
        "append_dimensions": {
          "ImageId": "\$${aws:ImageId}",
          "InstanceId": "\$${aws:InstanceId}",
          "InstanceType": "\$${aws:InstanceType}",
          "AutoScalingGroupName": "\$${aws:AutoScalingGroupName}"
        },
        "aggregation_dimensions" : [["ImageId"], ["InstanceId", "InstanceType"], ["d1"],[]],
        "force_flush_interval" : 30
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
                "log_group_name": "amazon-cloudwatch-agent.log",
                "log_stream_name": "amazon-cloudwatch-agent.log",
                "timezone": "UTC"
              },
              {
                "file_path": "/var/log/syslog",
                "log_group_name": "messages.log",
                "log_stream_name": "messages.log",
                "timezone": "Local"
              },
              {
                "file_path": "/home/ubuntu/app.log",
                "log_group_name": "app.log",
                "log_stream_name": "app.log",
                "timezone": "UTC"
              },
              {
                "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/test.log",
                "log_group_name": "test.log",
                "log_stream_name": "test.log",
                "timezone": "Local"
              }
            ]
          }
        },
        "log_stream_name": "my_log_stream_name",
        "force_flush_interval" : 15
      }
    }
EOT

sudo systemctl enable --now amazon-cloudwatch-agent

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
StandardOutput=file:/home/ubuntu/app.log
StandardError=file:/home/ubuntu/app.log
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

data "aws_default_tags" "asg_back" {
  tags = {
    Name = "tt-back"
  }
}

# Backend autoscaling group
resource "aws_autoscaling_group" "asg_back" {
  name                 = "tt-back"
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  launch_configuration = aws_launch_configuration.tt_lc_back.name
  vpc_zone_identifier  = var.private_subnets_back
  target_group_arns    = var.lb_target_group_back_arn
  dynamic "tag" {
    for_each = data.aws_default_tags.asg_back.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Bastion host - for debug purposes only
resource "aws_instance" "bastion" {
  count                = var.create_bastion ? 1 : 0
  instance_type        = var.instance_type
  ami                  = data.aws_ami.server_ami.id
  iam_instance_profile = var.instance_profile
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

# Install cloudwatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
sudo dpkg -i -E /tmp/amazon-cloudwatch-agent.deb

sudo tee -a /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOT
    {
      "agent": {
        "metrics_collection_interval": 10,
        "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
      },
      "metrics": {
        "namespace": "MyCustomNamespace",
        "metrics_collected": {
          "cpu": {
            "resources": [
              "*"
            ],
            "measurement": [
              {"name": "cpu_usage_idle", "rename": "CPU_USAGE_IDLE", "unit": "Percent"},
              {"name": "cpu_usage_nice", "unit": "Percent"},
              "cpu_usage_guest"
            ],
            "totalcpu": false,
            "metrics_collection_interval": 10,
            "append_dimensions": {
              "customized_dimension_key_1": "customized_dimension_value_1",
              "customized_dimension_key_2": "customized_dimension_value_2"
            }
          },
          "disk": {
            "resources": [
              "/",
              "/tmp"
            ],
            "measurement": [
              {"name": "free", "rename": "DISK_FREE", "unit": "Gigabytes"},
              "total",
              "used"
            ],
             "ignore_file_system_types": [
              "sysfs", "devtmpfs"
            ],
            "metrics_collection_interval": 60,
            "append_dimensions": {
              "customized_dimension_key_3": "customized_dimension_value_3",
              "customized_dimension_key_4": "customized_dimension_value_4"
            }
          },
          "diskio": {
            "resources": [
              "*"
            ],
            "measurement": [
              "reads",
              "writes",
              "read_time",
              "write_time",
              "io_time"
            ],
            "metrics_collection_interval": 60
          },
          "swap": {
            "measurement": [
              "swap_used",
              "swap_free",
              "swap_used_percent"
            ]
          },
          "mem": {
            "measurement": [
              "mem_used",
              "mem_cached",
              "mem_total"
            ],
            "metrics_collection_interval": 1
          },
          "net": {
            "resources": [
              "eth0"
            ],
            "measurement": [
              "bytes_sent",
              "bytes_recv",
              "drop_in",
              "drop_out"
            ]
          },
          "netstat": {
            "measurement": [
              "tcp_established",
              "tcp_syn_sent",
              "tcp_close"
            ],
            "metrics_collection_interval": 60
          },
          "processes": {
            "measurement": [
              "running",
              "sleeping",
              "dead"
            ]
          }
        },
        "append_dimensions": {
          "ImageId": "\$${aws:ImageId}",
          "InstanceId": "\$${aws:InstanceId}",
          "InstanceType": "\$${aws:InstanceType}",
          "AutoScalingGroupName": "\$${aws:AutoScalingGroupName}"
        },
        "aggregation_dimensions" : [["ImageId"], ["InstanceId", "InstanceType"], ["d1"],[]],
        "force_flush_interval" : 30
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
                "log_group_name": "amazon-cloudwatch-agent.log",
                "log_stream_name": "amazon-cloudwatch-agent.log",
                "timezone": "UTC"
              },
              {
                "file_path": "/var/log/syslog",
                "log_group_name": "messages.log",
                "log_stream_name": "messages.log",
                "timezone": "Local"
              },
              {
                "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/test.log",
                "log_group_name": "test.log",
                "log_stream_name": "test.log",
                "timezone": "Local"
              }
            ]
          }
        },
        "log_stream_name": "my_log_stream_name",
        "force_flush_interval" : 15
      }
    }
EOT

sudo systemctl enable --now amazon-cloudwatch-agent

EOF

}
