packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "learn-packer-linux-aws-hail"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}



source "amazon-ebs" "amzn2023" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"

  instance_type = "c5.large"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      #name                = "al2023-ami-minimal-2023.6.20250218.2-kernel-6.1-x86_64"
      name                = "al2023-ami-minimal-*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"] 
  }
  ssh_username = "ec2-user"
  launch_block_device_mappings {
    device_name          = "/dev/xvda"
    volume_size          = 100
    volume_type          = "gp3"
    delete_on_termination = true
  }
}

build {
  name = "learn-packer-al2023"
  sources = [
    "source.amazon-ebs.amzn2023"
  ]

  provisioner "shell" {
    inline = [
      "sudo dnf -y install nfs-utils rsync git",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "SPARK_VERSION=3.5.4",
      "SCALA_VERSION=2.12.18",
      "HAIL_VERSION=0.2.134"
    ]
		execute_command = "sudo -S bash -c 'ulimit -Sn && ulimit -Hn && {{ .Vars  }} {{ .Path  }}'"

		scripts = [ "scripts/hail_build.sh" ]
  }
}
