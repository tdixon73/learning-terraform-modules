resource "aws_security_group" "server_sg" {
  name = "${var.cluster_name}-sg"

  ingress {
    from_port = var.port
    to_port = var.port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb_sg" {
  name = "${var.cluster_name}-elb-sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_launch_configuration" "server_launch_config" {
    image_id        = "ami-0c55b159cbfafe1f0"
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.server_sg.id]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello World! ${var.cluster_name} is here!" > index.html
                nohup busybox httpd -f -p "${var.port}" &
                EOF
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_elb" "elb" {
  name = "${var.cluster_name}-asg-elb"
  security_groups = [aws_security_group.elb_sg.id]
  availability_zones = data.aws_availability_zones.all.names

  health_check {
    target              = "HTTP:${var.port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.port
    instance_protocol = "http"
  }
}


resource "aws_autoscaling_group" "server_group" {
  launch_configuration = aws_launch_configuration.server_launch_config.id
  availability_zones = data.aws_availability_zones.all.names

  min_size = var.min_size
  max_size = var.max_size

  load_balancers = [aws_elb.elb.name]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "${var.cluster_name}-asg-server"
    propagate_at_launch = true
  }
}