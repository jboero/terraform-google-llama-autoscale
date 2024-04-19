// John Boero - johnb@terasky.com
// Shared variables definition. This file defines the same variables across Terraform and Packer.
// Symlinking ./variables.tf to ./packer/variables.pkr.hcl allows both TF and Packer to use the same vars.

variable "region" {
  description = "Default region for configuring the Google provider. Make sure region has your GPU selection available."
  type        = string
  default     = "europe-west4"
}

variable "zone" {
  description = "Default zone for configuring the Google provider."
  type        = string
  default     = "europe-west4-c"
}

variable "network" {
  type    = string
  default = "llama"
}

variable "name" {
  type    = string
  default = "llama"
}

variable "project_id" {
  description = "Your project ID."
  type        = string
  default     = "<YOURPROJECT>"
}

variable "instance_type" {
  description = "Simple instances and slow networking are fine if GPU can fit your model."
  type        = string
  default     = "n1-standard-1"
}

variable "image" {
  description = "Select or build this image with the Packer template."
  type        = string
  default     = "llamacuda"
}

variable "gpu" {
  type        = string
  description = <<EOF
Which type of accelerator device to use. 
Find availability in your zone with `gcloud compute accelerator-types list`.
EOF
  default     = "nvidia-tesla-t4"
}

variable "gpu_count" {
  description = "How many GPUs do you need?"
  type        = number
  default     = 1
}

variable "port" {
  type    = number
  default = 8080
}

variable "min_replicas" {
  type    = number
  default = 1
}

variable "max_replicas" {
  type    = number
  default = 5
}

variable "load_balancing_scheme" {
  description = "Select load balancing scheme [EXTERNAL, EXTERNAL_MANAGED, INTERNAL_MANAGED, INTERNAL_SELF_MANAGED]."
  type        = string
  default     = "EXTERNAL_MANAGED"
}

variable "nvidia_driver" {
  type    = string
  default = "nvidia-driver-545"
}

variable "cuda_version" {
  type    = string
  default = "12.3.99"
}

variable "llama_model" {
  type    = string
  default = "amethyst-13b-mistral.Q4_K_M.gguf"
}

variable "llama_context_size" {
  type    = number
  default = 4096
}

variable "modelbucket" {
  type    = string
  default = "<YOURMODELBUCKET>"
}
