locals {
  topics = flatten([
    for topic in var.s3_with_trigger: {
      topic_name = topic.topic_name
      events = topic.events
    }
  ])
  buckets = flatten([
    for topic in var.s3_with_trigger: [
      for bucket in topic.buckets: {
        topic_name = topic.topic_name
        bucket_name = bucket
      }
    ]
  ])
}

data "aws_iam_policy_document" "main" {
  for_each = {
    for item in local.topics: item.topic_name => item
  }

  depends_on = [aws_s3_bucket.main]

  statement {
    sid = each.value.topic_name
    effect    = "Allow"
    resources = ["arn:aws:sns:*:*:${each.value.topic_name}"]
    actions   = ["SNS:Publish"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [for bucket in aws_s3_bucket.main: bucket.arn if bucket.tags.TopicName == each.value.topic_name]
    }

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic" "main" {
  for_each = {
    for item in local.topics: item.topic_name => item
  }

  name = each.value.topic_name

  policy = [for policy in data.aws_iam_policy_document.main: policy.json if policy.statement[0].sid == each.value.topic_name][0]
}

resource "aws_s3_bucket" "main" {
  for_each = {
    for item in local.buckets: item.bucket_name => item
  }

  bucket = each.value.bucket_name

  tags = {
    TopicName = each.value.topic_name
  }
}

resource "aws_s3_bucket_notification" "main" {
  for_each = {
    for item in local.buckets: item.bucket_name => item
  }

  depends_on = [aws_sns_topic.main, aws_s3_bucket.main]

  bucket = [for bucket in aws_s3_bucket.main: bucket.id if bucket.bucket == each.value.bucket_name][0]

  topic {
    topic_arn     = [for topic in aws_sns_topic.main: topic.arn if topic.name == each.value.topic_name][0]
    events        = [for topic in local.topics: topic.events if topic.topic_name == each.value.topic_name]
  }
}
