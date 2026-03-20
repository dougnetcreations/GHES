resource_group_name      = "rg-ghes-runners-prod"
location                 = "East US 2"
ghes_url                 = "https://ghe.yourcompany.com"

# Get from GHES: Settings → Actions → New self-hosted runner (Enterprise level)
ghes_runner_token        = "YOUR_ENTERPRISE_RUNNER_TOKEN"

# Image details (from Packer build output)
image_gallery_name       = "ghesRunnerGallery"
image_resource_group_name = "rg-ghes-images"
gallery_image_name       = "ubuntu-runner"
runner_image_version     = "1.0.20260320"  # Update after Packer

subnet_id                = "/subscriptions/.../subnets/runners"

runner_vm_size           = "Standard_D4s_v5"
runner_min_count         = 0
runner_max_count         = 100
jobs_per_runner          = 2.5
runner_labels           = ["ubuntu", "ephemeral", "compliance", "D4s"]

tags = {
  Environment = "Production"
  Purpose     = "GHES-Autoscaling-Runners"
}
