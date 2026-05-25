variable "project_id" {
  type = string
}

variable "api_keys" {
  type      = string
  sensitive = true
  default   = ""
}

variable "create_api_key_secret" {
  type    = bool
  default = true
}

variable "service_account_email" {
  type    = string
  default = ""
}
