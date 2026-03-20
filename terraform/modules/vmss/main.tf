resource "random_id" "suffix" { byte_length = 6 }

resource "azurerm_linux_virtual_machine_scale_set" "runners" {
  name                = "ghesrunners${random_id.suffix.hex}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.runner_vm_size
  instances           = var.runner_min_count
  admin_username      = "runner"

  source_image_id = var.runner_image_id
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    diff_disk_enabled    = true  # Fresh disk per VM
  }

  network_interface {
    name    = "default"
    primary = true
    ip_configuration {
      name              = "internal"
      primary           = true
      subnet_id         = var.subnet_id
      public_ip_enabled = false
    }
  }

  # EPHEMERAL RUNNER - destroys itself after 1 job
  custom_data = base64encode(templatefile("${path.module}/runner.sh", {
    ghes_url  = var.ghes_url
    ghes_token = var.ghes_token
  }))

  tags = var.tags
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name               = "ghes-autoscale-${random_id.suffix.hex}"
  resource_group_name = var.resource_group_name
  location           = var.location
  target_resource_id = azurerm_linux_virtual_machine_scale_set.runners.id

  profile {
    name = "default"
    capacity {
      default = var.runner_min_count
      minimum = var.runner_min_count
      maximum = var.runner_max_count
    }
    
    # Scale OUT when jobs queue up
    rule {
      metric_trigger {
        metric_name        = "JobQueueLength"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.runners.id
        comparison         = "GreaterThan"
        threshold          = 2
        time_grain         = "PT1M"
        time_window        = "PT5M"
      }
      scale_action {
        direction = "Increase"
        value     = "10"
        cooldown  = "PT2M"
      }
    }
    
    # Scale IN when quiet
    rule {
      metric_trigger {
        metric_name        = "JobQueueLength"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.runners.id
        comparison         = "LessThan"
        threshold          = 1
        time_grain         = "PT1M"
        time_window        = "PT5M"
      }
      scale_action {
        direction = "Decrease"
        value     = "5"
        cooldown  = "PT10M"
      }
    }
  }
}
