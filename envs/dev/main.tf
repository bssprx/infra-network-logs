module "networking" {
  source = "../../modules/networking"

  # CIDR block for the VPC
  vpc_cidr_block        = "10.210.32.0/22"
  # Public subnet CIDRs
  public_subnet_cidrs   = ["10.210.32.0/24", "10.210.33.0/24"]
  # Private subnet CIDRs
  private_subnet_cidrs  = ["10.210.34.0/24", "10.210.35.0/24"]
  availability_zones    = ["us-east-1a", "us-east-1c"]
  # Prefix for resource names
  name_prefix           = "bssprx"

  # Environment name
  environment = "dev"
  # Project name
  project     = "infra-network-logs"

  tags = {
    Environment = "dev"
    Project     = "infra-network-logs"
  }

  # Transit gateway ID for routing
  transit_gateway_id     = "tgw-0f08b9a1e117882f2"
  # Routes to add to the transit gateway
  transit_gateway_routes = [
    "10.201.4.0/22",
    "10.201.12.0/22",
    "10.209.99.0/26",
    "172.20.1.0/24",
    "172.30.1.0/24"
  ]
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "logging_sg_id" {
  value = module.networking.logging_sg_id
}

resource "aws_instance" "logging_node" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = module.networking.public_subnet_ids[0]
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [module.networking.logging_sg_id]

  user_data = file("user_data.sh")

  root_block_device {
    volume_size = 60
    volume_type = "gp3"
  }

  tags = {
    Name        = "network-logging-node"
    Environment = var.environment
    Project     = var.project
  }
}
