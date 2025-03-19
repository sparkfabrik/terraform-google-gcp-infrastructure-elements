# Terraform Gcp Infrastructure Elements

This project is intended to gather common elements for GCP infrastructures in order to centralize security configurations and best practices.

We suggest following Terraform best practices as described in https://www.terraform-best-practices.com/code-structure.

## SSL default policy
Creates a default policy for SSL that disables unsecure ciphers and tls<1.2

## Google Cloud Logging Exclusions

Creates standard logging exclusions for Google Cloud projects.

### Features

- Creates a health probe exclusion to filter out traffic from monitoring systems
- Creates a default exclusion for common Kubernetes system logs
- Configurable list of probe user agents to exclude

### Usage

```hcl
module "logging_exclusions" {
  source = "./modules/logging-exclusions"
  
  project_id = var.project
  
  # Selectively enable or disable specific exclusions
  enable_exclusions = {
    probe_exclusion                   = true
    default_k8s_exclusion             = true
    gke_metadata_server_sync_sandbox  = false  # Disable this exclusion
  }
}
```
<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.13 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.13 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_exclusions"></a> [custom\_exclusions](#input\_custom\_exclusions) | Map of custom exclusion filters with their descriptions | <pre>map(object({<br>    filter      = string<br>    description = string<br>  }))</pre> | `{}` | no |
| <a name="input_default_exclusion_filter"></a> [default\_exclusion\_filter](#input\_default\_exclusion\_filter) | Filter for default log exclusion | `string` | `"resource.type=\"k8s_cluster\" AND (protoPayload.authenticationInfo.principalEmail=~\"container-engine-robot.iam.gserviceaccount.com\" OR protoPayload.authenticationInfo.principalEmail=\"system:kubestore-collector\" OR protoPayload.authenticationInfo.principalEmail=\"system:cloud-controller-manager\" OR protoPayload.authenticationInfo.principalEmail=\"system:kube-scheduler\" OR protoPayload.authenticationInfo.principalEmail=\"system:cluster-autoscaler\" OR protoPayload.authenticationInfo.principalEmail=\"system:l7-lb-controller\" OR protoPayload.authenticationInfo.principalEmail=\"system:kube-controller-manager\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:metrics-server\" OR protoPayload.authenticationInfo.principalEmail=\"system:addon-manager\" OR protoPayload.authenticationInfo.principalEmail=\"system:vpa-recommender\" OR protoPayload.authenticationInfo.principalEmail=\"system:gke-master-healthcheck\" OR protoPayload.authenticationInfo.principalEmail=\"system:managed-certificate-controller\" OR protoPayload.authenticationInfo.principalEmail=\"system:clustermetrics\" OR protoPayload.authenticationInfo.principalEmail=\"system:pd-csi-controller\" OR protoPayload.authenticationInfo.principalEmail=\"system:konnectivity-server\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:kube-dns-autoscaler\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:generic-garbage-collector\" OR protoPayload.authenticationInfo.principalEmail=\"system:gke-common-webhooks\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:resourcequota-controller\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:konnectivity-agent-cpha\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:persistent-volume-binder\" OR (protoPayload.authenticationInfo.principalEmail=\"system:apiserver\" AND protoPayload.methodName=\"io.k8s.core.v1.endpoints.get\") OR protoPayload.methodName=~\"watch\" OR protoPayload.methodName=~\"io.k8s.apiserver.flowcontrol\" OR protoPayload.methodName=~\"io.k8s.discovery.v1.endpointslices\" OR protoPayload.methodName=~\"io.k8s.v1.nodes.watch\" OR protoPayload.methodName=~\"io.k8s.coordination.v1.leases\" OR protoPayload.methodName=~\"io.k8s.core.v1.componentstatuses\" OR protoPayload.methodName=~\"io.k8s.autoscaling\" OR protoPayload.methodName=~\"io.k8s.metrics.v1beta1\" OR protoPayload.methodName=~\"io.k8s.authorization.v1.selfsubjectaccessreviews\" OR protoPayload.methodName=~\"io.k8s.core.v1.nodes.status.patch\" OR (protoPayload.methodName=~\"io.k8s.get\" AND protoPayload.resourceName =~ \"metrics\") OR (protoPayload.methodName=~\"io.k8s.core.v1.configmaps.get\" AND protoPayload.resourceName =~ \"metrics\") OR protoPayload.resourceName=\"readyz\" OR protoPayload.resourceName=\"livez\")\n"` | no |
| <a name="input_enable_exclusions"></a> [enable\_exclusions](#input\_enable\_exclusions) | Map of boolean flags to enable/disable individual exclusions | `map(bool)` | <pre>{<br>  "default_k8s_exclusion": true,<br>  "fluentbit_gke": true,<br>  "fpm": true,<br>  "gke_metadata_server_sync_sandbox": true,<br>  "probe_exclusion": true<br>}</pre> | no |
| <a name="input_enable_ssl_policy"></a> [enable\_ssl\_policy](#input\_enable\_ssl\_policy) | Enable SSL policy creation | `bool` | `true` | no |
| <a name="input_fluentbit_gke"></a> [fluentbit\_gke](#input\_fluentbit\_gke) | Fluentbit-gke exclusion for failed to parse time | `string` | `"resource.labels.container_name=\"fluentbit-gke\" AND \njsonPayload.message=~\"Failed to parse time\"\n"` | no |
| <a name="input_fpm"></a> [fpm](#input\_fpm) | FPM exclusion | `string` | `"resource.type=\"container\" AND\n\"fpm\" AND\n( \n  ( trace:* sample(trace, 0.5) ) OR\n  ( NOT trace:* operation.id:* sample(operation.id, 0.5) ) OR\n  ( NOT trace:* NOT operation.id:* sample(insertId, 0.5) ) \n)\n"` | no |
| <a name="input_gke_metadata_server_exclusion_sync_sandbox"></a> [gke\_metadata\_server\_exclusion\_sync\_sandbox](#input\_gke\_metadata\_server\_exclusion\_sync\_sandbox) | Filter for gke-metadata-server exclusion for failed to sync sandbox | `string` | `"resource.type=\"k8s_container\" AND\nseverity=INFO AND\nresource.labels.namespace_name=\"kube-system\" AND\nlabels.k8s-pod/k8s-app=\"gke-metadata-server\" AND\njsonPayload.message=~\"Unable to sync sandbox\"\n"` | no |
| <a name="input_probe_user_agents"></a> [probe\_user\_agents](#input\_probe\_user\_agents) | List of probe user agents to exclude from logs | `list(string)` | <pre>[<br>  "kube-probe",<br>  "GoogleHC"<br>]</pre> | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID where logging exclusions will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_exclusion_id"></a> [default\_exclusion\_id](#output\_default\_exclusion\_id) | The ID of the default exclusion resource |
| <a name="output_fluentbit_gke_exclusion_id"></a> [fluentbit\_gke\_exclusion\_id](#output\_fluentbit\_gke\_exclusion\_id) | The ID of the Fluentbit GKE exclusion resource |
| <a name="output_fpm_exclusion_id"></a> [fpm\_exclusion\_id](#output\_fpm\_exclusion\_id) | The ID of the FPM exclusion resource |
| <a name="output_gke_metadata_server_exclusion_id"></a> [gke\_metadata\_server\_exclusion\_id](#output\_gke\_metadata\_server\_exclusion\_id) | The ID of the GKE metadata server exclusion resource |
| <a name="output_probe_exclusion_filter"></a> [probe\_exclusion\_filter](#output\_probe\_exclusion\_filter) | The filter used for probe exclusions |
| <a name="output_probe_exclusion_id"></a> [probe\_exclusion\_id](#output\_probe\_exclusion\_id) | The ID of the probe exclusion resource |

## Resources

| Name | Type |
|------|------|
| [google_compute_ssl_policy.modern_tls_1_2](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_policy) | resource |
| [google_logging_project_exclusion.custom_exclusions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.default_exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.fluentbit_gke_parse_time](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.fpm](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.gke_metadata_server_exclusion_sync_sandbox](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.probe_exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |

## Modules

No modules.

<!-- END_TF_DOCS -->
