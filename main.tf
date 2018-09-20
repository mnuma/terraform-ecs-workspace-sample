variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}
variable "key_name" {}
variable "vpc_zone_id" {}
variable "ecs_sg_id" {}

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

variable "ecs_cluster_name" {
  default = "sample-cluster"
}

variable "ecs_image_id" {
  default = "ami-0d5f884dada5562c6"
}

variable "ecs_assume_role_file" {
    default = "sample-ecs-assume-role.json"
}

variable "desired_count" {
  default = 1
}

resource "aws_ecs_cluster" "sample_ecs_cluster" {
  name = "${var.env}-${var.ecs_cluster_name}"
}

resource "aws_iam_role" "sample_ecs_service_role" {
  name               = "${var.env}-sample-ecs-service-role"
  assume_role_policy = "${file("${var.ecs_assume_role_file}")}"
}

resource "aws_ecs_task_definition" "sample_api" {
  family                = "${var.env}-sample-api"
  container_definitions = "${file("${var.container_definitions_file}")}"
}

resource "aws_ecs_service" "sample_api_service" {
  name                               = "${var.env}-sample-api-service"
  cluster                            = "${aws_ecs_cluster.sample_ecs_cluster.id}"
  task_definition                    = "${aws_ecs_task_definition.sample_api.arn}"
  desired_count                      = "${var.desired_count}"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
}

resource "aws_launch_configuration" "sample_api" {
  image_id              = "${var.ecs_image_id}"
  key_name              = "${var.key_name}"
  instance_type         = "t3.micro"
  iam_instance_profile  = "ecsInstanceRole"
  security_groups       = ["${var.ecs_sg_id}"]
  associate_public_ip_address = "true"
  user_data                   = <<EOF
  #!/bin/bash
  echo ECS_CLUSTER=${aws_ecs_cluster.sample_ecs_cluster.name} >> /etc/ecs/ecs.config
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "sample_api" {
  name                  = "${var.env}-sample-ecs-asg"
  availability_zones    = ["ap-northeast-1a", "ap-northeast-1c"]
  launch_configuration  = "${aws_launch_configuration.sample_api.id}"
  vpc_zone_identifier   = ["${var.vpc_zone_id}"]
  min_size              = 1
  max_size              = 1
  desired_capacity      = 1
  health_check_type     = "EC2"
  tags = [
    {
      key                 = "Name"
      value               = "${var.env}-sample"
      propagate_at_launch = true
    }
  ]
}
