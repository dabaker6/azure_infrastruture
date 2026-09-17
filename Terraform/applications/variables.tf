variable "product" {
  description = "The name of the product to create."
  type        = string
  default     = ""
}

variable "web_app_repo_name" {
  description = "Front end webapp repo name."
  type        = string
}

variable "web_app_image_tag" {
  description = "Tag of image to use for front end webapp."
  type        = string
  default     = "latest"
}

variable "cric_api_repo_name" {
  description = "Front end webapp image name."
  type        = string
}

variable "cric_api_image_tag" {
  description = "Tag of image to use for front end webapp."
  type        = string
  default     = "latest"
}

variable "cric_api_cosmos_permission" {
  type    = string
  default = "00000000-0000-0000-0000-000000000001"
}

variable "cric_api_version" {
  type = string
}

variable "personal_website_subnet_web_app_prefixes" {
  type = list(string)
}

variable "personal_website_subnet_cric_api_prefixes" {
  type = list(string)
}

variable "scaling_name" {
  type = string
}

variable "scaling_worker_message_count" {
  type    = number
  default = 500
}

variable "scaling_worker_processing_time" {
  type    = number
  default = 500
}

variable "scaling_worker_image_tag" {
  type    = string
  default = "latest"
}

variable "scaling_worker_cooldown_period_in_seconds" {
  type    = number
  default = 300
}

variable "scaling_worker_interval_in_seconds" {
  type    = number
  default = 30
}

variable "scaling_worker_min_replicas" {
  type    = number
  default = 0
}

variable "scaling_worker_max_replicas" {
  type    = number
  default = 5
}

variable "scaling_api_image_tag" {
  type    = string
  default = "latest"
}

variable "scaling_api_version" {
  type = string
}

variable "scaling_api_background_polling" {
  type    = string
  default = "10000"
}

variable "scaling_api_polling" {
  type    = string
  default = "3000"
}

variable "websites_port" {
  type    = number
  default = 8000
}

variable "github_org" {
  type    = string
  default = "dabaker6"
}

variable "scaling_repo" {
  type    = string
  default = "aca_scaling_api"
}