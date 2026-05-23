variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "repository_id" {
  type    = string
  default = "cybertranspay"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "service_account_email" {
  type    = string
  default = ""
}

variable "allow_unauthenticated" {
  type    = bool
  default = false
}

variable "min_instances" {
  type    = number
  default = 0
}
