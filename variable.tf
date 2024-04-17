variable "environment" {
  description = "환경 이름"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC 대역대"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_private_subnet" {
  description = "프라이빗 서브넷 생성"
  type        = bool
  default     = false
}