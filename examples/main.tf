terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  name                       = "gke-test-1"
  region                     = "us-central1"
  zones                      = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                    = "vpc-01"
  subnetwork                 = "us-central1-01"
  ip_range_pods              = "us-central1-01-gke-01-pods"
  ip_range_services          = "us-central1-01-gke-01-services"
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  dns_cache                  = false

  node_pools = [
    {
      name                       = "default-node-pool"
      machine_type               = "e2-medium"
      node_locations             = "us-central1-b,us-central1-c"
      min_count                  = 1
      max_count                  = 100
      local_ssd_count            = 0
      spot                       = false
      disk_size_gb               = 100
      disk_type                  = "pd-standard"
      image_type                 = "COS_CONTAINERD"
      enable_gcfs                = false
      enable_gvnic               = false
      logging_variant            = "DEFAULT"
      auto_repair                = true
      auto_upgrade               = true
      service_account            = "project-service-account@${var.project_id}.iam.gserviceaccount.com"
      preemptible                = false
      initial_node_count         = 80
      accelerator_count          = 1
      accelerator_type           = "nvidia-l4"
      gpu_driver_version         = "LATEST"
      gpu_sharing_strategy       = "TIME_SHARING"
      max_shared_clients_per_gpu = 2
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 12.0"

  project_id   = var.project_id
  network_name = "example-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = "us-west1"
    },
    {
      subnet_name           = "subnet-02"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = "us-west1"
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
      description           = "This subnet has a description"
    },
    {
      subnet_name               = "subnet-03"
      subnet_ip                 = "10.10.30.0/24"
      subnet_region             = "us-west1"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    }
  ]

  secondary_ranges = {
    subnet-01 = [
      {
        range_name    = "subnet-01-secondary-01"
        ip_cidr_range = "192.168.64.0/24"
      },
    ]

    subnet-02 = []
  }

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    },
    {
      name                   = "app-proxy"
      description            = "route through proxy to reach app"
      destination_range      = "10.50.10.0/24"
      tags                   = "app-proxy"
      next_hop_instance      = "app-proxy-instance"
      next_hop_instance_zone = "us-west1-a"
    },
  ]
}

module "infrastructure_elements" {
  source = ".."

  # core module inputs
  project_id = var.project_id

  # Kyverno firewall example: override as needed
  kyverno_firewall_rule = {
    enable        = true
    network       = module.vpc.network_self_link
    source_ranges = [module.gke.master_ipv4_cidr_block]
  }
}
