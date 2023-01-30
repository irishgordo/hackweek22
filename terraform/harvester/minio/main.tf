resource "harvester_network" "ext-vlan-minio" {
  name      = "vlan-minio"
  namespace = "default"

  vlan_id = 900

  route_mode           = "auto"
  route_dhcp_server_ip = ""

  cluster_network_name = "external"
}

resource "harvester_image" "ubuntu2204-jammy-minio" {
  name      = "ubuntu-2204-jammy-minio"
  namespace = "default"
  storage_class_name = "harvester-longhorn"
  display_name = "jammy-server-cloudimg-amd64-disk-kvm-minio.img"
  source_type  = "download"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
}

resource "harvester_ssh_key" "minio-ssh-key" {
  name      = "minio-ssh-key"
  namespace = "default"

  public_key = var.SSH_KEY
}

locals {
  cloud_init_config_base = <<-EOF
      #cloud-config
      password: ${var.MINIO_VM_PW}
      chpasswd:
        expire: false
      ssh_pwauth: true
      package_update: true
      packages:
        - qemu-guest-agent
        - apt-transport-https
        - neovim
        - wget
        - ca-certificates
        - curl
        - gnupg-agent
        - gnupg
        - lsb-release
        - software-properties-common
        - coreutils
        - tmux
      write_files:
        - path: /tmp/minio
          owner: ubuntu:ubuntu
          content: |
            MINIO_VOLUMES="${var.MINIO_VOLUMES}"
            MINIO_OPTS="--console-address ${var.MINIO_CONSOLE_ADDRESS} --address ${var.MINIO_ADDRESS}"
            MINIO_ROOT_USER="${var.MINIO_ROOT_USER}"
            MINIO_ROOT_PASSWORD="${var.MINIO_ROOT_PASSWORD}"
        - path: /tmp/minio.service
          owner: ubuntu:ubuntu
          content: |
            [Unit]
            Description=MinIO
            Documentation=https://docs.min.io
            Wants=network-online.target
            After=network-online.target
            AssertFileIsExecutable=/usr/local/bin/minio

            [Service]
            WorkingDirectory=/usr/local/

            User=minio-user
            Group=minio-user
            ProtectProc=invisible

            EnvironmentFile=/etc/default/minio
            ExecStartPre=/bin/bash -c "if [ -z \"\${var.MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"
            ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

            # Let systemd restart this service always
            Restart=always

            # Specifies the maximum file descriptor number that can be opened by this process
            LimitNOFILE=65536

            # Specifies the maximum number of threads this process can create
            TasksMax=infinity

            # Disable timeout logic and wait until process is stopped
            TimeoutStopSec=infinity
            SendSIGKILL=no

            [Install]
            WantedBy=multi-user.target
      runcmd:
        - - systemctl
          - enable
          - --now
          - qemu-guest-agent.service
        - wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
        - sudo dpkg -i amazon-ssm-agent.deb
        - sudo service amazon-ssm-agent stop
        - sudo -E amazon-ssm-agent -register -id ${var.SSM_REGISTER_ID} -code ${var.SSM_REGISTER_CODE} -region ${var.SSM_REGION}
        - sudo service amazon-ssm-agent start
        - wget
          ${var.MINIO_VERSION_DEB_PKG}
          -O minio.deb
        - dpkg -i minio.deb
        - mkdir -p ${var.MINIO_VOLUMES}
        - mkdir -p /var/log/minio
        - groupadd -r minio-user
        - useradd -M -r -g minio-user minio-user
        - chown -Rv minio-user:minio-user /home/minio-user
        - chown -Rv minio-user:minio-user ${var.MINIO_VOLUMES}
        - chmod -R minio-user=rwx ${var.MINIO_VOLUMES}
        - mkdir -p /etc/default
        - cp -v /tmp/minio /etc/default/minio
        - chown -v minio-user:minio-user /etc/default/minio
        - cp -v /tmp/minio.service /etc/systemd/system
        - systemctl daemon-reload
        - systemctl daemon-reload
        - systemctl enable minio
        - systemctl start minio
      ssh_authorized_keys:
        - ${var.SSH_KEY}
EOF
}

resource "kubernetes_secret" "minio-cloud-config-secret" {
  metadata {
    name      = "minio-cc-secret"
    namespace = "default"
    labels = {
      "sensitive" = "false"
    }
  }
  data = {
    "userdata" = local.cloud_init_config_base
  }
}

resource "harvester_virtualmachine" "miniovm" {
  depends_on = [
    kubernetes_secret.minio-cloud-config-secret
  ]
  name                 = "miniobox"
  namespace            = "default"
  restart_after_update = true

  description = "MinIO S3 Backup Server"
  tags = {
    ssh-user = "ubuntu"
  }

  cpu    = 2
  memory = "4Gi"

  efi         = true
  secure_boot = false

  run_strategy = "RerunOnFailure"
  hostname     = "miniobox"
  machine_type = "q35"

  ssh_keys = [
    harvester_ssh_key.minio-ssh-key.id
  ]

  network_interface {
    name           = "nic-1"
    wait_for_lease = true
    model = "virtio"
    type = "bridge"
    network_name = harvester_network.ext-vlan-minio.id
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = "40Gi"
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.ubuntu2204-jammy-minio.id
    auto_delete = true
  }

# https://deploy.equinix.com/developers/guides/minio/
  cloudinit {
    user_data_secret_name = "minio-cc-secret"
    network_data = ""
  }
}