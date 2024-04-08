// John Boero - johnb@terasky.com
// Shared variables definition. This file defines the same variables across Terraform and Packer.
// Symlinking ./variables.tf to ./packer/variables.pkr.hcl allows both TF and Packer to use the same vars.

variable "region" {
  type    = string
  default = "europe-west4"
}

variable "zone" {
  type    = string
  default = "europe-west4-b"
}

variable "project_id" {
  type    = string
  default = "skywiz-sandbox"
}

variable "instance_type" {
  type    = string
  default = "n1-standard-1"
}

variable "gpu" {
  type    = string
  default = "nvidia-tesla-v100"
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
  default = "tsllamamodels"
}

/* This only works in Packer
variable authtoken {
  type = string
  #default = env("GOOGLE_APPLICATION_CREDENTIALS")
}
*/