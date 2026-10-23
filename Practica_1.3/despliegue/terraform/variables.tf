variable "region" {
  description = "Región de AWS donde desplegar"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.small"
}

variable "project" {
  description = "Prefijo del proyecto, usado para nombrar recursos"
  type        = string
  default     = "rundash-lb"
}
