# ──────────────────────────────────────────────────────────────
# EC2 Module – Provisions a VM, installs Docker, and deploys
# a containerized web application (Nginx-based).
# Home: Terraform Docker Deployment template
# /madhan-profile: Downloaded from S3 at boot
# ──────────────────────────────────────────────────────────────

# ── Latest Amazon Linux 2 AMI ────────────────────────────────
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ── Security Group ───────────────────────────────────────────
resource "aws_security_group" "web" {
  name        = "terraform-docker-sg"
  description = "Allow HTTP, HTTPS, and SSH traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-docker-sg"
  }
}

# ── EC2 Instance with Docker + Container ─────────────────────
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data_replace_on_change = true
  user_data                   = <<-EOF
#!/bin/bash
set -euxo pipefail
yum update -y
amazon-linux-extras install docker -y
systemctl enable docker && systemctl start docker
usermod -aG docker ec2-user
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir -p /opt/webapp/madhan-profile
cat > /opt/webapp/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Terraform Docker Deployment</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}body{font-family:'Segoe UI',Arial,sans-serif;min-height:100vh;display:grid;place-items:center;background:linear-gradient(135deg,#0f0c29,#302b63,#24243e);color:#e2e8f0}.card{background:rgba(255,255,255,0.06);backdrop-filter:blur(12px);border:1px solid rgba(255,255,255,0.12);border-radius:16px;padding:48px 40px;width:min(520px,92vw);text-align:center;box-shadow:0 8px 32px rgba(0,0,0,0.3)}.card h1{font-size:2rem;margin-bottom:12px;background:linear-gradient(90deg,#667eea,#764ba2);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.card p{color:#94a3b8;line-height:1.6}.badge{display:inline-block;margin-top:20px;padding:6px 16px;border-radius:999px;font-size:0.85rem;font-weight:600;background:rgba(102,126,234,0.15);color:#667eea;border:1px solid rgba(102,126,234,0.3)}.nav-link{display:inline-block;margin-top:28px;padding:12px 32px;border-radius:12px;font-size:0.95rem;font-weight:600;text-decoration:none;color:#fff;background:linear-gradient(135deg,#667eea,#764ba2);transition:all 0.3s ease;box-shadow:0 4px 15px rgba(102,126,234,0.4)}.nav-link:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(102,126,234,0.6)}
</style>
</head>
<body>
<main class="card">
<h1>Containerized Deployment</h1>
<p>This application is running inside a <strong>Docker container</strong>, provisioned automatically using <strong>Terraform</strong> on AWS EC2.</p>
<span class="badge">Nginx &middot; Docker &middot; Terraform</span><br/>
<a href="/madhan-profile/" class="nav-link">View AutoServe Pro &rarr;</a>
</main>
</body>
</html>
HTML
S3URL="${var.s3_bucket_url}"
curl -o /opt/webapp/madhan-profile/index.html "$S3URL/profile.html"
sed -i "s|S3_URL_PLACEHOLDER|$S3URL|g" /opt/webapp/madhan-profile/index.html
cat > /opt/webapp/nginx.conf <<'NGINX'
server {
    listen 80;
    server_name localhost;
    location / { root /usr/share/nginx/html; index index.html; }
    location /madhan-profile/ { alias /usr/share/nginx/html/madhan-profile/; index index.html; }
    location /health { access_log off; return 200 'OK'; add_header Content-Type text/plain; }
}
NGINX
cat > /opt/webapp/docker-compose.yml <<'COMPOSE'
version: "3.8"
services:
  webapp:
    image: nginx:alpine
    container_name: terraform-webapp
    restart: always
    ports:
      - "80:80"
    volumes:
      - ./index.html:/usr/share/nginx/html/index.html:ro
      - ./madhan-profile:/usr/share/nginx/html/madhan-profile:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost/health"]
      interval: 30s
      timeout: 5s
      retries: 3
COMPOSE
cd /opt/webapp && docker-compose up -d
echo "=== Deployment complete ==="
EOF

  tags = {
    Name        = "Terraform-DockerHost"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
