data "google_client_config" "default" {}


module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 3.1"
  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name   = var.subnetwork
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    (var.subnetwork) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}
module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  project_id                 = var.project_id
  name                       = var.cluster_name
  region                     = var.region
  zones                      = ["europe-west3-a", "europe-west3-b", "europe-west3-c"]
  network                    = module.gcp-network.network_name
  subnetwork                 = module.gcp-network.subnets_names[0]
  ip_range_pods              = var.ip_range_pods_name
  ip_range_services          = var.ip_range_services_name
  http_load_balancing        = true
  initial_node_count         = 1
  depends_on = [
    module.gcp-network
  ]

  node_pools = [
    {
      name               = "parity-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 1
      max_count          = 2
      disk_size_gb       = 50
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = var.gcp-nodepool-service-account
      preemptible        = false
      initial_node_count = 0
      ignore_changes =   "initial_node_count"
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
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
      node-pool-metadata-custom-value = "polkadot"
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
resource "kubernetes_namespace" "monitoring" {
  metadata {
    annotations = {
      name = "monitoring"
    }

    labels = {
      app = "monitoring"
    }

    name = "monitoring"
  }
  depends_on = [
    module.gke
  ]
}

resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  namespace = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  values = [
    file("${path.module}/nginx-values.yaml")
  ]
  depends_on = [
    module.gke,
    kubernetes_namespace.monitoring
  ] 
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    annotations = {
      name = "cert-manager"
    }

    labels = {
      app = "cert-manager"
    }

    name = "cert-manager"
  }
  depends_on = [
    module.gke
  ]
}

resource "helm_release" "jetstack" {
  name       = "jetstack"
  namespace = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"

  # values = [
  #   file("${path.module}/jetstack-values.yaml")
  # ]
  set {
    name  = "installCRDs"
    value = true
  }
  set {
    name = "prometheus.enabled"
    value = true
  }
  depends_on = [
    module.gke,
    kubernetes_namespace.cert-manager
  ] 
}



resource "kubernetes_namespace" "nginx-ingress-controller" {
  metadata {
    annotations = {
      name = "nginx-ingress-controller"
    }

    labels = {
      app = "nginx-ingress"
    }

    name = "nginx-ingress-controller"
  }
  depends_on = [
    module.gke
  ]
}

resource "helm_release" "nginx" {
  name       = "ingress-nginx"
  namespace = "nginx-ingress-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  values = [
    file("${path.module}/nginx-values.yaml")
  ]
  depends_on = [
    module.gke,
    kubernetes_namespace.nginx-ingress-controller
  ] 
}

resource "kubernetes_namespace" "polkadot-node" {
  metadata {
    annotations = {
      name = "polkadot-node"
    }

    labels = {
      app = "polkadot-node"
    }

    name = "polkadot-node"
  }
  depends_on = [
    module.gke
  ]
}

resource "helm_release" "polkadot-default-node" {
  name       = "polkadot-node"
  namespace =  "polkadot-node"
  repository = "https://paritytech.github.io/helm-charts/"
  chart      = "node"

  values = [
    file("${path.module}/polkadot-node-values.yaml")
  ]
  depends_on = [
    helm_release.nginx,
    kubernetes_namespace.polkadot-node
  ] 
}

resource "kubernetes_namespace" "kusama-node" {
  metadata {
    annotations = {
      name = "kusama-node"
    }

    labels = {
      app = "kusama-node"
    }

    name = "kusama-node"
  }
  depends_on = [
    module.gke,
    kubernetes_namespace.kusama-node
  ]
}

resource "helm_release" "kusama-default-node" {
  name       = "kusama-node"
  namespace = "kusama-node"
  repository = "https://paritytech.github.io/helm-charts/"
  chart      = "node"

  values = [
    file("${path.module}/kusama-node-values.yaml")
  ]
  depends_on = [
    helm_release.nginx
  ]
}

resource "kubernetes_namespace" "substrate-telemetry" {
  metadata {
    annotations = {
      name = "substrate-telemetry"
    }

    labels = {
      app = "substrate-telemetry"
    }

    name = "substrate-telemetry"
  }
  depends_on = [
    module.gke,
    kubernetes_namespace.substrate-telemetry
  ]
}

resource "helm_release" "substrate-telemetry" {
  name       = "substrate-telemetry"
  namespace = "substrate-telemetry"
  repository = "https://paritytech.github.io/helm-charts/"
  chart      = "substrate-telemetry"
# By default, the type of Kubernetes service used for Telemetry-Core, Telemetry-Shard and Telemetry-Frontend is ClusterIP, 
# so they're not accessible from outside of the k8s cluster. 
# Consider exposing all of the services using service of type LoadBalancer or using an ingress controller:
  values = [
    file("${path.module}/substrate-telemetry-values.yaml")
  ]
  depends_on = [
    helm_release.nginx
  ]
}