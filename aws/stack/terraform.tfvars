region = "us-east-2"

profile = "arley_tests"

vpc = [
  {
    name = "poc-test-net"
    cidr_block = "10.26.0.0/24"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    subnets = [
      {
        name = "poc-test-public-1"
        cidr_block = "10.26.0.0/26"
        availability_zone = "us-east-2a"
      },
      {
        name = "poc-test-public-2"
        cidr_block = "10.26.0.64/26"
        availability_zone = "us-east-2b"
      },
      {
        name = "poc-test-private-1"
        cidr_block = "10.26.0.128/26"
        availability_zone = "us-east-2a"
      },
      {
        name = "poc-test-private-2"
        cidr_block = "10.26.0.192/26"
        availability_zone = "us-east-2b"
      }
    ]
    nat_gateways = [
      {
        name = "poc-nat-public-1"
        subnet = "poc-test-public-1"
        elastic_ip = {
          name = "poc-eip-public-1"
          vpc = true
        }
      }
    ]
    router_tables = [
      {
        name = "poc-test-public"
        subnets = [
          "poc-test-public-1",
          "poc-test-public-2"
        ]
        routes = [
          {
            cidr_block = "0.0.0.0/0"
            nat_gateway = ""
            gateway_name = "poc-test-net-internet-gateway"
            vpc_peering_connection_id = ""
          }
        ]
      },
      {
        name = "poc-test-private"
        subnets = [
          "poc-test-private-1",
          "poc-test-private-2"
        ]
        routes = [
          {
            cidr_block = "0.0.0.0/0"
            nat_gateway = "poc-nat-public-1"
            gateway_name = ""
            vpc_peering_connection_id = ""
          }
        ]
      }
    ]
    security_groups = [
      {
        name = "poc-test-security-group"
        ingress = [
          {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = [
              "0.0.0.0/0"
            ]
          }
        ]
        egress = [
          {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = [
              "0.0.0.0/0"
            ]
          }
        ]
      }
    ]
    acl = [
      {
        name    = "poc-test-acl-public"
        subnets = [
          "poc-test-public-1",
          "poc-test-public-2"
        ]
        egress = [
          {
            protocol   = "-1"
            rule_no    = 100
            action     = "allow"
            cidr_block = "0.0.0.0/0"
            from_port  = 0
            to_port    = 0
          }
        ]
        ingress = [
          {
            protocol   = "-1"
            rule_no    = 100
            action     = "allow"
            cidr_block = "0.0.0.0/0"
            from_port  = 0
            to_port    = 0
          }
        ]
      },
      {
        name    = "poc-test-acl-private"
        subnets = [
          "poc-test-private-1",
          "poc-test-private-2"
        ]
        egress = [
          {
            protocol   = "-1"
            rule_no    = 100
            action     = "allow"
            cidr_block = "0.0.0.0/0"
            from_port  = 0
            to_port    = 0
          }
        ]
        ingress = [
          {
            protocol   = "tcp"
            rule_no    = 100
            action     = "allow"
            cidr_block = "10.26.0.0/26"
            from_port  = 22
            to_port    = 22
          },
          {
            protocol   = "tcp"
            rule_no    = 101
            action     = "allow"
            cidr_block = "10.26.0.64/26"
            from_port  = 22
            to_port    = 22
          },
          {
            protocol   = "tcp"
            rule_no    = 102
            action     = "allow"
            cidr_block = "0.0.0.0/0"
            from_port  = 80
            to_port    = 80
          },
          {
            protocol   = "tcp"
            rule_no    = 103
            action     = "allow"
            cidr_block = "0.0.0.0/0"
            from_port  = 1024
            to_port    = 65535
          },
          {
            protocol   = "udp"
            rule_no    = 104
            action     = "allow"
            cidr_block = "0.0.0.0/0"
            from_port  = 123
            to_port    = 123
          }
        ]
      }
    ]
  }
]

s3_with_trigger = [
  {
    topic_name = "s3-update-notification-topic"
    buckets = [
      "s3-poc-test-4"
    ]
    events = "s3:ObjectCreated:*"
  }
]

ec2 = [
  {
    name = "poc-test-web-server"
    ami = "ami-0b614a5d911900a9b"
    instance_type = "t2.micro"
    key_name = "arley_test_key"
    key_output = "./../services/compute/ec2/keys/arley_test_key.pem"
    monitoring = true
    vpc_security_group_ids = [
      "poc-test-security-group"
    ]
    subnet_id = "poc-test-private-1"
    tags = {
      "Name" : "poc-test-web-server",
      "selector" : "poc-test-web-server"
    }
    user_data_path = "./../services/compute/ec2/scripts/install_apache.sh"
  }
]

load_balancers = [
  {
      name : "poc-test-web-server-lb"
      subnets : [
        "poc-test-public-1",
        "poc-test-public-2"
      ]
      instances : [
        "poc-test-web-server"
      ]
      security_groups = [
        "poc-test-security-group"
      ]
      listeners : [
        {
          instance_port     = 80
          instance_protocol = "http"
          lb_port           = 80
          lb_protocol       = "http"
        }
      ]
      health_checks = [
        {
          healthy_threshold   = 2
          unhealthy_threshold = 2
          timeout             = 3
          target              = "HTTP:80/"
          interval            = 30
        }
      ]
      tags : {
        Name = "poc-test-web-server-lb"
      }
  }
]
