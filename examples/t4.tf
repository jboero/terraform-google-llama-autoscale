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
