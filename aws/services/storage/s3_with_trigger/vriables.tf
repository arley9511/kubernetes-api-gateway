variable "s3_with_trigger" {
  description = ""

  type = list(object({
    topic_name = string
    buckets = list(string)
    events = string
  }))
}
