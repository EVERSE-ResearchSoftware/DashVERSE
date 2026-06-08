variable "namespace" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = { app = "dashverse" }
}
