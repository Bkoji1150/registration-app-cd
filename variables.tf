
variable "component_name" {
  type        = string
  description = "(optional) describe your variable"
  default     = "registration-app-cd"
}

variable "db_name" {
  type        = string
  description = "(optional) describe your variable"
  default     = "webappdb"
}

variable "port" {
  type        = number
  description = "(optional) describe your variable"
  default     = 3306
}

variable "instance_class" {
  type        = string
  description = "(optional) describe your variable"
  default     = "db.t2.micro"
}

variable "username" {
  type        = string
  description = "(optional) describe your variable"
  default     = "registrationuser"
}

variable "container_version" {
  type        = string
  description = "Please provide the container version"
}