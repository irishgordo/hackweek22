# switching to convention over configuration, dropping local.yaml at the root of the project 'should' suffice
# variable "KUBECONFIG_LOCATION" {
#     description = "the full file path location of the kubeconfig"
#     type = string
# }

variable "SSH_KEY" {
  description = "your public ssh key"
  type = string
}

variable "SSM_AGENT_TEMP_DIR" {
  description = "aws ssm agent temp dir location"
  type = string
  default = "/tmp/ssm"
}

variable "SSM_AGENT_OUTPUT_FILEPATH" {
  description = "aws ssm agent output name"
  type = string
  default = "/tmp/ssm/amazon-ssm-agent.deb"
}

variable "SSM_AGENT_INSTALL_URL" {
  description = "aws ssm agent install url"
  type = string
  default = "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb"
}

variable "SSM_REGISTER_ID" {
  description = "register id to register hybrid harvester vm instance with aws ssm"
  type = string
  sensitive = true
}

variable "SSM_REGISTER_CODE" {
  description = "register code to register hybrid harvester vm instance with aws ssm"
  type = string
  sensitive = true
}

variable "SSM_REGION" {
  description = "aws region to register managed harvester instance vm with"
  type = string
}

variable "MINIO_VM_PW" {
  description = "vm password for minio"
  type = string
  sensitive = false
  default = "ubuntupw"
}

variable "MINIO_DESIRED_CPU" {
  description = "the desired cpu"
  type = number
  default = 2
}

variable "MINIO_DESIRED_MEM" {
  description = "the desired mem"
  type = string
  default = "4Gi"
}

variable "MINIO_VOLUMES" {
  description = "volumes"
  type = string
  default = "/var/www/minio"
}

variable "MINIO_DISK_SIZE" {
  description = "disk size"
  type = string
  default = "40Gi"
}

variable "MINIO_NAME" {
  description = "minio host name"
  type = string
  default = "miniobox"
}

variable "MINIO_ROOT_USER" {
  description = "minio root user, the username"
  type = string
  default = "minioadmin"
}

variable "MINIO_ROOT_PASSWORD" {
  description = "minio root user password for console"
  type = string
  default = "minioadmin"
  sensitive = false
}

variable "MINIO_CONSOLE_ADDRESS" {
  description = "the address to access the web front end, well it can just be port, it could be abcdefg.localdoma:PORTNUMBER"
  type = string
  default = ":8000"
}

variable "MINIO_ADDRESS" {
  description = "address that gets used for the S3 url like http://blah-something:PORT"
  type = string
  default = ":8080"

}

variable "MINIO_VERSION_DEB_PKG" {
  description = "deb pkg ver"
  type = string
  default = "https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20221111034420.0.0_amd64.deb"
}