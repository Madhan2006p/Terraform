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

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Madhan</title>
      <link rel="stylesheet" href="styles.css" />
    </head>
    <body>
      <main class="card">
        <h1>Madhan</h1>
        <p>Static page hosted on S3 using Terraform.</p>
      </main>
    </body>
    </html>
  HTML
}

resource "aws_s3_object" "styles" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "styles.css"
  content_type = "text/css"
  content      = <<-CSS
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: Arial, sans-serif;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background: #eef2ff;
      color: #111827;
    }
    .card {
      background: #ffffff;
      border: 1px solid #dbeafe;
      border-radius: 12px;
      padding: 24px;
      width: min(420px, 92vw);
      text-align: center;
    }
    .card h1 { margin-bottom: 8px; }
    .card p { color: #4b5563; }
  CSS
}

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
