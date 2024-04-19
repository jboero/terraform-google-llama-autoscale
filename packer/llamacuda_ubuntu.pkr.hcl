/** /
John Boero - johnb@terasky.com
A Packer template with Nvidia drivers and Llama.cpp server for GCP autoscale groups.

Uses env var GOOGLE_APPLICATION_CREDENTIALS for token (not file path) by default.
Removing authtoken will use GOOGLE_APPLICATION_CREDENTIALS as file path to token instead.
At the time of writing there is no standardized DEB packaging for Llama CUDA unlike the RPMs.
So shoot from the hip 🔫 with improvised build/install unsigned code... 
Not recommended for production or use the official build container.
/**/
packer {
  required_plugins {
    googlecompute = {
      version = "~> v1.1.4"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

# Thid only works for Packer
variable authtoken {
  type = string
  default = env("GOOGLE_APPLICATION_CREDENTIALS")
}

source "googlecompute" "llamacuda" {
  image_name              = "llamacuda"
  machine_type            = var.instance_type
  disk_size               = "20"
  accelerator_type        = "projects/${var.project_id}/zones/${var.zone}/acceleratorTypes/${var.gpu}"
  accelerator_count       = 1
  access_token            = var.authtoken
  #source_image            = "ubuntu-2204-jammy-v20240319"
  source_image_family     = "ubuntu-2204-lts"
  ssh_username            = "packer"
  temporary_key_pair_type = "rsa"
  temporary_key_pair_bits = 2048
  zone                    = var.zone
  project_id              = var.project_id
  on_host_maintenance     = "TERMINATE"
}

build {
  sources = ["source.googlecompute.llamacuda"]
  provisioner "file" {
    destination = "/tmp/llama.service"
    content     = <<EOF
[Unit]
Description=Llama.cpp server CUDA build.
After=syslog.target network.target local-fs.target remote-fs.target nss-lookup.target

[Service]
Type=simple
User=llama
#EnvironmentFile=/etc/sysconfig/llama
ExecStart=/usr/bin/llamaserver -m /mnt/${var.llama_model} -c ${var.llama_context_size} -ngl 100 --host 0.0.0.0 --port 8080
ExecReload=/bin/kill -s HUP 
Restart=never

[Install]
WantedBy=default.target
EOF
  }

  provisioner "shell" {
    inline = [ <<EOF
      set -x
      echo Adding repos...
      curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
      sudo bash add-google-cloud-ops-agent-repo.sh --also-install
      sudo add-apt-repository multiverse
      export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
      echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.asc

      echo Updating and installing packages...
      sudo apt update
      sudo apt upgrade -y
      sudo apt install -y nvidia-cuda-toolkit gcsfuse git make build-essential ${var.nvidia_driver}
      sudo modprobe nvidia

      echo Adding models bucket to fstab... read-only, allow_other, and _netdev required.
      echo "${var.modelbucket} /mnt gcsfuse ro,allow_other,_netdev" | sudo tee -a /etc/fstab

      nvidia-smi || echo "Failed nvidia-smi.. continuing"
      git clone https://github.com/ggerganov/llama.cpp.git
      cd llama.cpp
      make -j4 LLAMA_CUDA=1 LLAMA_FAST=1 CUDA_DOCKER_ARCH=all CUDA_VERSION=${var.cuda_version} server

      # Crude unsigned installation.
      sudo useradd llama
      sudo mv /tmp/llama.service /usr/lib/systemd/system/
      sudo chown root:root ./server /usr/lib/systemd/system/llama.service
      sudo mv server /usr/bin/llamaserver
      sudo setcap cap_net_bind_service=+ep /usr/bin/llamaserver
      sudo systemctl daemon-reload
      sudo mount -a
      sudo systemctl enable --now llama.service
      sleep 5
      sudo systemctl status llama.service

      wait
      EOF
    ]
  }
}
