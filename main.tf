#Author: gustavocalcaterra

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {
  description = "DigitalOcean API token"
}

resource "digitalocean_droplet" "mongo" {
  count = 3
  image = "almalinux-8-x64"
  name  = "mongo-${count.index + 1}"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
  ssh_keys = [var.ssh_key_fingerprint]

  tags = ["mongodb"]
}

variable "ssh_key_fingerprint" {
  description = "SSH key fingerprint for the droplets"
}

output "mongo_public_ips" {
  value = digitalocean_droplet.mongo.*.ipv4_address
}


output "mongo_private_ips" {
  value = digitalocean_droplet.mongo.*.ipv4_address_private
}

resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [mongodb]
    %{ for droplet in digitalocean_droplet.mongo.* ~}
    ${droplet.name} ansible_host=${droplet.ipv4_address} private_ip=${droplet.ipv4_address_private} ansible_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa
    %{ endfor ~}
  EOT

  filename = "${path.module}/inventory.ini"
  depends_on = [digitalocean_droplet.mongo]
}
