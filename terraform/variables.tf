variable "public_key_path" {
  description = "Ruta al archivo de clave pública"
  type        = string
}

variable "private_key_path" {
  description = "Ruta al archivo de clave privada (.pem)"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  default     = "t3.large"
  type        = string
}
