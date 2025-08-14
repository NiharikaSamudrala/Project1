variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type    = string
  default = "mydemo-bucket-0906"
}

variable "script_s3_path" {
  type        = string
  description = "S3 URI of the Glue ETL script"
  default     = "s3://mydemo-bucket-0906/scripts/myscript.py"
}
