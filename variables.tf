variable "instance_id" {
  description = "ID of the existing EC2 instance"
  type        = string
}

variable "device_name" {
  description = "Device name of the EBS volume (e.g., /dev/xvda)"
  type        = string
}