# Load balanced managed VMs
The resources/services/activations/deletions that this module will create/trigger are:
> grep -rn resource main.tf 
* resource "google_compute_instance_template" "llama"
* resource "google_compute_instance_group_manager" "llama"
* resource "google_compute_target_pool" "llama"
* resource "google_compute_autoscaler" "llama"
* resource "google_compute_url_map" "llama"
* resource "google_compute_target_http_proxy" "llama"
* resource "google_compute_global_forwarding_rule" "llama"
* resource "google_compute_backend_service" "llama"
* resource "google_compute_health_check" "llama"
* resource "google_compute_firewall" "allow_lb_health_check"

### Tagline
Create an autoscaling managed instance group of VM spot instances with GPU for Llama.cpp inference clustering. Make sure to build the included Llama.cpp Packer template into your project or build your own image.

### Detailed
Create a regional autoscaling group of spot VMs with GPUs that run Llama.cpp server on the GGUF model of your choice. Store your model in GCS. Adjust the Packer config if necessary and build your image. Then deploy this module with that image into your region with your GPU selection.

### Architecture
1. The user utilizes the load balancer IP output by the module.
2. Load balancing distributes requests using plain text to an autoscale group of spot VM instances based on the model type and GPU type.
3. The Packer image must be built separately for the autoscale group.
4. Models are uploaded to GCS which is mounted with GCSFUSE to /mnt within each VM.
5. Each VM will try to launch Llama.cpp server with the config provided in Packer. Runtime config like cloud-init isn't as easy with autoscale groups.
6. Health checks must be allowed from the outisde by firewall policy on Llama's port.
7. If TLS is desired on the LB then certs and DNS must be configured externally.

## Documentation
- [Architecture Diagram](https://github.com/GoogleCloudPlatform/terraform-google-load-balanced-vms/blob/main/assets/load_balanced_vms_v1.svg)

## Usage

Basic usage of this module is as follows:

```hcl
module "terraform-google-llama-autoscale" {
    source          = "terasky/llama-autoscale"
    project_id      = "<PROJECT ID>"
    name            = "llama"
    region          = "europe-west4"
    zone            = "europe-west4-c"
    network         = "llama"
    instance_type   = "n1-standard-1"
    image           = "llamacuda"
    gpu             = "nvidia-tesla-v100"
    port            = 8080
    min_replicas    = 2
    max_replicas    = 10
    llama_model     = "amethyst-13b-mistral.Q5_K_M.gguf"
    llama_context_size  = 4096
    modelbucket     = "<YourModelBucket>"
}

```

## Open in Cloud Shell
An other way of using this Terraform solution is with DeployStack, which will
ask for setting options in Cloud Shell.

<a href="https://shell.cloud.google.com/cloudshell/editor?show=terminal&cloudshell_git_repo=https://github.com/GoogleCloudPlatform/terraform-google-load-balanced-vms&cloudshell_image=gcr.io%2Fds-artifacts-cloudshell%2Fdeploystack_custom_image" target="_new">
    <img alt="Open in Cloud Shell" src="https://gstatic.com/cloudssh/images/open-btn.svg">
</a>

Functional examples are included in the
[examples](./examples/) directory.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deployment\_name | The name of this particular deployment, will get added as a prefix to most resources. | `string` | `"load-balanced-vms"` | no |
| enable\_apis | Whether or not to enable underlying apis in this solution. . | `string` | `true` | no |
| labels | A map of labels to apply to contained resources. | `map(string)` | <pre>{<br>  "load-balanced-vms": true<br>}</pre> | no |
| network\_id | VPC network to deploy VMs in. A VPC will be created if not specified. | `string` | `""` | no |
| network\_project\_id | Shared VPC host project ID if a Shared VPC is provided via network\_id. | `string` | `""` | no |
| nodes | The number of nodes in the managed instance group | `string` | n/a | yes |
| project\_id | The project ID to deploy to | `string` | n/a | yes |
| region | The Compute Region to deploy to | `string` | n/a | yes |
| subnet\_self\_link | Subnetwork to deploy VMs in. A Subnetwork will be created if not specified. | `string` | `""` | no |
| zone | The Compute Zone to deploy to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| endpoint | The IPv4 of the public endpoint |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

1. Create your bucket and upload your chosen models.
2. Build the Packer image or customize it how you like. Make sure to update config to point to your model in bucket.

### Software

The following dependencies must be available:

### Service Account

A service account with the following roles must be used to provision the resources of this module:

- Compute Admin: `roles/compute.admin`

The [Project Factory module][project-factory-module] and the [IAM module][iam-module] may be used in combination to provision a service account with the necessary roles applied.

GPU quotas must be available for both Packer image build and Terraform deploy.

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud Compute API: `compute.googleapis.com`

The [Project Factory module][project-factory-module] can be used to
provision a project with the necessary APIs enabled.

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html


This is not an official Google product