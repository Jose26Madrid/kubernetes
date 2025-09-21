variable "private_key_path" {
  description = "Ruta al archivo de clave privada (.pem) para SSH desde Terraform"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.large"
}
