variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}
variable "key_name" {}
variable "vpc_zone_id" {}
variable "vpc_subnet_id_1" {}
variable "vpc_subnet_id_2" {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

variable "env" {
  default = "staging3"
}

variable "aws_zone" {
  default = "ap-northeast-1c"
}

variable "container_definitions_file" {
  default = "sample_api.json"
}

variable "project_name" {
  default = "sample-api"
}

variable "ecs_image_id" {
  default = "ami-0d5f884dada5562c6"
}

variable "ecs_assume_role_file" {
  default = "sample_ecs_assume_role.json"
}

variable "desired_count" {
  default = 1
}

resource "aws_ecs_cluster" "sample_api" {
  name = "${var.env}-${var.project_name}-cluster"
}

resource "aws_iam_role" "sample_api_ecs_service" {
  name               = "${var.env}-${var.project_name}-service-role"
  assume_role_policy = "${file("${var.ecs_assume_role_file}")}"
}

resource "aws_ecs_task_definition" "sample_api" {
  family                = "${var.env}-${var.project_name}"
  container_definitions = "${file("${var.container_definitions_file}")}"
}

resource "aws_ecs_service" "sample_api" {
  name                               = "${var.env}-${var.project_name}-service"
  cluster                            = "${aws_ecs_cluster.sample_api.id}"
  task_definition                    = "${aws_ecs_task_definition.sample_api.arn}"
  desired_count                      = "${var.desired_count}"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
}

resource "aws_iam_role" "sample_api_ecs_instance" {
  name               = "${var.env}-${var.project_name}-instance-role"
  assume_role_policy = "${file("${var.ecs_assume_role_file}")}"
}

variable "sample_api_ecs_instance_role_policy_arns" {
  type = "list"
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
  ]
}

resource "aws_iam_role_policy_attachment" "sample_api_ecs_instance" {
  role       = "${aws_iam_role.sample_api_ecs_instance.name}"
  count      = "${length(var.sample_api_ecs_instance_role_policy_arns)}"
  policy_arn = "${var.sample_api_ecs_instance_role_policy_arns[count.index]}"
}

resource "aws_iam_instance_profile" "sample_api_ecs_instance" {
  name = "${var.env}-${var.project_name}-instance-profile"
  path = "/"
  role = "${aws_iam_role.sample_api_ecs_instance.name}"
}

resource "aws_security_group" "sample_api_ecs_instance" {
  vpc_id      = "${var.vpc_zone_id}"
  name        = "${var.env}-${var.project_name}-sg"
  description = "${var.env} sg sample api ecs instance"

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.env}-${var.project_name}-sg"
  }
}

resource "aws_launch_configuration" "sample_api_ecs_instance" {
  image_id                    = "${var.ecs_image_id}"
  key_name                    = "${var.key_name}"
  instance_type               = "t3.micro"
  iam_instance_profile        = "${aws_iam_instance_profile.sample_api_ecs_instance.name}"
  security_groups             = ["${aws_security_group.sample_api_ecs_instance.id}"]
  associate_public_ip_address = "true"
  user_data                   = <<EOF
  #!/bin/bash
  echo ECS_CLUSTER=${aws_ecs_cluster.sample_api.name} >> /etc/ecs/ecs.config
  yum install -y https://amazon-ssm-ap-northeast-1.s3.amazonaws.com/latest/linux_amd64/amazon-ssm-agent.rpm
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "sample_api" {
  name                  = "${var.env}-${var.project_name}"
  availability_zones    = ["ap-northeast-1a", "ap-northeast-1c"]
  launch_configuration  = "${aws_launch_configuration.sample_api_ecs_instance.id}"
  vpc_zone_identifier   = ["${var.vpc_subnet_id_1}", "${var.vpc_subnet_id_2}"]
  min_size              = 2
  max_size              = 2
  desired_capacity      = 2
  health_check_type     = "EC2"
  tags = [
    {
      key                 = "Env"
      value               = "${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "ECS Instance - ${var.env}-${var.project_name}"
      propagate_at_launch = true
    }
  ]
}
