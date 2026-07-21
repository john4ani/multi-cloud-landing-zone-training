variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "tags" {
  type = map(string)
  default = {
    application = "cloud-architecture-training"
    environment = "bootstrap"
    managed_by  = "terraform"
    owner       = "training"
  }
}

output "bucket_name" { value = aws_s3_bucket.state.bucket }
