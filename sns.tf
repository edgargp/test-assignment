resource "aws_sns_topic" "email_topic" {
  name = "email-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.email_topic.arn
  protocol  = "email"
  endpoint  = "edgar.gomtsyan@gmail.com"
}