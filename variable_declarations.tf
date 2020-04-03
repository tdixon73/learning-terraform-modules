variable "port" {
  default = 8080
}

variable "cluster_name" {
  type = string
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}