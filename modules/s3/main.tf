# ──────────────────────────────────────────────────────────────
# S3 Module – Image Storage for AutoServe Pro Portfolio
# Stores project screenshots, served as a public image CDN
# ──────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "bucket" {
  bucket = "madhan-terraform-bucket-2026-001"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ── CORS Configuration (allow EC2 to fetch images) ──────────
resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3600
  }
}

# ── Upload Project Screenshots ──────────────────────────────

resource "aws_s3_object" "image_1" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "images/1.png"
  source       = "${path.root}/images/1.png"
  content_type = "image/png"
  etag         = filemd5("${path.root}/images/1.png")
}

resource "aws_s3_object" "image_2" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "images/2.png"
  source       = "${path.root}/images/2.png"
  content_type = "image/png"
  etag         = filemd5("${path.root}/images/2.png")
}

resource "aws_s3_object" "image_3" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "images/3.png"
  source       = "${path.root}/images/3.png"
  content_type = "image/png"
  etag         = filemd5("${path.root}/images/3.png")
}

resource "aws_s3_object" "image_4" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "images/4.png"
  source       = "${path.root}/images/4.png"
  content_type = "image/png"
  etag         = filemd5("${path.root}/images/4.png")
}

resource "aws_s3_object" "image_5" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "images/5.png"
  source       = "${path.root}/images/5.png"
  content_type = "image/png"
  etag         = filemd5("${path.root}/images/5.png")
}

resource "aws_s3_object" "image_6" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "images/6.png"
  source       = "${path.root}/images/6.png"
  content_type = "image/png"
  etag         = filemd5("${path.root}/images/6.png")
}

resource "aws_s3_object" "image_7" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "images/7.png"
  source       = "${path.root}/images/7.png"
  content_type = "image/png"
  etag         = filemd5("${path.root}/images/7.png")
}

resource "aws_s3_object" "image_8" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "images/8.png"
  source       = "${path.root}/images/8.png"
  content_type = "image/png"
  etag         = filemd5("${path.root}/images/8.png")
}

resource "aws_s3_object" "image_9" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "images/9.png"
  source       = "${path.root}/images/9.png"
  content_type = "image/png"
  etag         = filemd5("${path.root}/images/9.png")
}

# ── Public Read Policy ──────────────────────────────────────
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.public_access]
}
