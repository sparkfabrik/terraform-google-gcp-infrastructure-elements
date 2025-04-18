variable "project_id" {
  description = "The Google Cloud project ID where logging exclusions will be created"
  type        = string
}

###########################
# SSL default policy
###########################
variable "enable_ssl_policy" {
  description = "Enable SSL policy creation"
  type        = bool
  default     = true
}

variable "ssl_modern_policy_description" {
  description = "Description for the SSL policy"
  type        = string
  default     = "Modern SSL policy with minimum TLS version 1.2"
}

###########################
# Logging Exclusions 
###########################
variable "enable_exclusions" {
  description = "Map of boolean flags to enable/disable individual exclusions"
  type        = map(bool)
  default = {
    probe_exclusion                  = true
    default_k8s_exclusion            = true
    gke_metadata_server_sync_sandbox = true
    fluentbit_gke                    = true
    fpm                              = true
  }
}

variable "probe_user_agents" {
  description = "List of probe user agents to exclude from logs"
  type        = list(string)
  default = [
    "kube-probe",
    "GoogleHC"
  ]
}

variable "default_exclusion_filter" {
  description = "Filter for default log exclusion"
  type        = string
  default     = <<EOT
resource.type="k8s_cluster" AND (protoPayload.authenticationInfo.principalEmail=~"container-engine-robot.iam.gserviceaccount.com" OR protoPayload.authenticationInfo.principalEmail="system:kubestore-collector" OR protoPayload.authenticationInfo.principalEmail="system:cloud-controller-manager" OR protoPayload.authenticationInfo.principalEmail="system:kube-scheduler" OR protoPayload.authenticationInfo.principalEmail="system:cluster-autoscaler" OR protoPayload.authenticationInfo.principalEmail="system:l7-lb-controller" OR protoPayload.authenticationInfo.principalEmail="system:kube-controller-manager" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:metrics-server" OR protoPayload.authenticationInfo.principalEmail="system:addon-manager" OR protoPayload.authenticationInfo.principalEmail="system:vpa-recommender" OR protoPayload.authenticationInfo.principalEmail="system:gke-master-healthcheck" OR protoPayload.authenticationInfo.principalEmail="system:managed-certificate-controller" OR protoPayload.authenticationInfo.principalEmail="system:clustermetrics" OR protoPayload.authenticationInfo.principalEmail="system:pd-csi-controller" OR protoPayload.authenticationInfo.principalEmail="system:konnectivity-server" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:kube-dns-autoscaler" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:generic-garbage-collector" OR protoPayload.authenticationInfo.principalEmail="system:gke-common-webhooks" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:resourcequota-controller" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:konnectivity-agent-cpha" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:persistent-volume-binder" OR (protoPayload.authenticationInfo.principalEmail="system:apiserver" AND protoPayload.methodName="io.k8s.core.v1.endpoints.get") OR protoPayload.methodName=~"watch" OR protoPayload.methodName=~"io.k8s.apiserver.flowcontrol" OR protoPayload.methodName=~"io.k8s.discovery.v1.endpointslices" OR protoPayload.methodName=~"io.k8s.v1.nodes.watch" OR protoPayload.methodName=~"io.k8s.coordination.v1.leases" OR protoPayload.methodName=~"io.k8s.core.v1.componentstatuses" OR protoPayload.methodName=~"io.k8s.autoscaling" OR protoPayload.methodName=~"io.k8s.metrics.v1beta1" OR protoPayload.methodName=~"io.k8s.authorization.v1.selfsubjectaccessreviews" OR protoPayload.methodName=~"io.k8s.core.v1.nodes.status.patch" OR (protoPayload.methodName=~"io.k8s.get" AND protoPayload.resourceName=~"metrics") OR (protoPayload.methodName=~"io.k8s.core.v1.configmaps.get" AND protoPayload.resourceName=~"metrics") OR protoPayload.resourceName="readyz" OR protoPayload.resourceName="livez")
EOT
}

variable "gke_metadata_server_exclusion_sync_sandbox" {
  description = "Filter for gke-metadata-server exclusion for failed to sync sandbox"
  type        = string
  default     = <<EOT
resource.type="k8s_container" AND
severity=INFO AND
resource.labels.namespace_name="kube-system" AND
labels.k8s-pod/k8s-app="gke-metadata-server" AND
jsonPayload.message=~"Unable to sync sandbox"
EOT
}

variable "fluentbit_gke" {
  description = "Fluentbit-gke exclusion for failed to parse time"
  type        = string
  default     = <<EOT
resource.labels.container_name="fluentbit-gke" AND 
jsonPayload.message=~"Failed to parse time"
EOT
}

variable "fpm" {
  description = "FPM exclusion"
  type        = string
  default     = <<EOT
resource.type="container" AND
"fpm" AND
( 
  ( trace:* sample(trace, 0.5) ) OR
  ( NOT trace:* operation.id:* sample(operation.id, 0.5) ) OR
  ( NOT trace:* NOT operation.id:* sample(insertId, 0.5) ) 
)
EOT
}

variable "custom_exclusions" {
  description = "Map of custom exclusion filters with their descriptions"
  type = map(object({
    filter      = string
    description = string
  }))
  default = {}
}
