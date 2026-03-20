packer {
  required_plugins {
    azure = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

source "azure-arm" "ubuntu" "eastus2" {
  client_id       = "{{env `ARM_CLIENT_ID`}}"
  client_secret   = "{{env `ARM_CLIENT_SECRET`}}"
  subscription_id = "{{env `ARM_SUBSCRIPTION_ID`}}"
  tenant_id       = "{{env `ARM_TENANT_ID`}}"
  
  managed_image_name   = "ghes-runner-ubuntu-{{timestamp}}"
  managed_image_resource_group_name = "rg-ghes-images"
  location            = "East US 2"
  os_type             = "Linux"
  image_publisher      = "Canonical"
  image_offer          = "0001-com-ubuntu-server-jammy"
  image_sku            = "22_04-lts-gen2"
  vm_size              = "Standard_D2s_v5"
  admin_username       = "runner"
}

build {
  sources = ["source.azure-arm.ubuntu.eastus2"]
  provisioner "shell" {
    inline = [
      "sudo apt-get update && sudo apt-get upgrade -y",
      "sudo apt-get install -y docker.io docker-compose jq curl git helm kubectl awscli azure-cli",
      "sudo systemctl enable docker && sudo systemctl start docker",
      "sudo usermod -aG docker runner",
      "mkdir -p /opt/actions-runner && chown runner:runner /opt/actions-runner"
    ]
  }
}
