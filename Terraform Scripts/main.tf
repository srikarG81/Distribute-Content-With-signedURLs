resource "aws_s3_bucket" "docs-bucket" {
  bucket = "docs-bucket-1803"
  tags = {
    Name = "docs-bucket-1803"
  }
}

resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.docs-bucket.id
  acl    = "private"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_identity" "example" {
  comment = "Docs store"
}


resource "aws_cloudfront_public_key" "cf_public_key" {
  comment     = "test public key"
  encoded_key = file("public_key.pem")
  name        = "test_key"
}


resource "aws_cloudfront_key_group" "cf_keygroup" {
  comment = "key group"
  items   = [aws_cloudfront_public_key.cf_public_key.id]
  name    = "cf_keygroup"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.docs-bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.example.cloudfront_access_identity_path
    }
  }



  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    trusted_key_groups = [aws_cloudfront_key_group.cf_keygroup.id]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

price_class = "PriceClass_200"

 restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.docs-bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.example.iam_arn]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.docs-bucket.arn,
      "${aws_s3_bucket.docs-bucket.arn}/*",
    ]
  }
}


output "aws_cloudfront_public_key_ID" {
  value = aws_cloudfront_public_key.cf_public_key.id
}

output "aws_cloudfront_Destribution" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}





