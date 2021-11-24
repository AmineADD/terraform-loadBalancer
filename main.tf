
terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  zone            = "fr-par-1"
  region          = "fr-par"
  project_id = "bfdf1982-baf5-4378-86de-e6a194cef3d4"

}

resource "scaleway_instance_ip" "webServer" {
  count = 2
} 
resource "scaleway_instance_placement_group" "group" {
  count = 2
}
resource "scaleway_lb_ip" "ip" {
}

resource "scaleway_lb" "balancer" { 
  type  = "lb-s"
  ip_id = scaleway_lb_ip.ip.id
}





resource "scaleway_rdb_instance" "database" {
  name           = "database"
  node_type      = "db-dev-s"
  engine         = "PostgreSQL-12"
  is_ha_cluster  = false 
  user_name     = var.userName
  password      = var.Password
}

variable "userName" {
  type = string
}

variable "Password" {
  type = string
}


resource "scaleway_instance_security_group" "web" {
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept" 
  inbound_rule {
    action = "accept"
    port   = "443"
    ip     = scaleway_lb.balancer.ip_address
  }
}
 
resource "scaleway_instance_server" "web" {
  count = 2
  name = "server"
  type = "dev1-s"
  image = "ubuntu_focal"
  ip_id = scaleway_instance_ip.webServer[count.index].id
  security_group_id  = scaleway_instance_security_group.web.id
  placement_group_id = scaleway_instance_placement_group.group[count.index].id
  user_data = {
    DATABASE_URI="postgres://admin:admin@scaleway_instance_ip.public_ip.id:60696/database"
  }
 
}

resource "scaleway_lb_backend" "loadbl" { 
  lb_id = scaleway_lb.balancer.id
  name             = "loadbl"
  forward_protocol = "http"
  forward_port     = "80"
  server_ips       = [for o in scaleway_instance_ip.webServer : o.address]
}

