![llama_autoscale](https://github.com/jboero/terraform-google-llama-autoscale/assets/7536012/213355de-de3c-45e4-a0c6-d68fd5249e93)
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

> grep variable variables.tf 
region: The region to deploy a single cluster in. Default "europe-west4"
zone:   The zone to deploy a single cluster in. Default "europe-west4-a"
network: The network to use for deployment. Default "default"
name:    What to name each of the resources created for this cluster. Default "llama"
project_id: Project ID to use.
instance_type: What VM instance type to use for the instance template. Default "n1-standard-1"
image: Name of the image to use. This should be built with Packer first. Default "llamacuda"
gpu: Type of GPU to use in each instance. Must be available in region. Default "nvidia-tesla-t4"
gpu_count: Count of GPUs per instance. Default 1
port: Port to serve llama.cpp server on IPv4 0.0.0.0. Default 8080
min_replicas: Minimum number of replicas in the managed instance group. Default 1
max_replicas: Max number of replicas. Default 5
load_balancing_scheme: Google LB scheme. Default "EXTERNAL_MANAGED"
nvidia_driver: (Packer only) Version of the Nvidia drivers to build Packer image with. Ignored in Terraform. Default "nvidia-driver-545"
cuda_version: (Packer only) Version of CUDA to build the Packer image with. Ignored in Terraform. Default "12.3.99"
llama_model: (Packer only) Name/path of the model file in your bucket. This will be mounted at /mnt in the VM. Default "amethyst-13b-mistral.Q4_K_M.gguf"
llama_context_size: (Packer only) Context size to run Llama.cpp server with. Default 4096
modelbucket: (Packer only) Name of the GCS bucket to mount read-only at /mnt in the VM image. Ignored in Terraform. (required)

## Outputs

| Name | Description |
|------|-------------|
| endpoint | The IPv4 of the public endpoint |

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
