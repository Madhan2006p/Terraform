# ──────────────────────────────────────────────────────────────
# EC2 Module – Provisions a VM, installs Docker, and deploys
# a containerized web application (Nginx-based).
# Home: Terraform Docker Deployment template
# /madhan-profile: AutoServe Pro consultancy project showcase
# Images served from S3 bucket
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

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom app port (8080) – useful for direct container access
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

              # ── System updates ──
              yum update -y

              # ── Install Docker ──
              amazon-linux-extras install docker -y
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user

              # ── Install Docker Compose ──
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
                -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose

              # ── Create application directory ──
              mkdir -p /opt/webapp/madhan-profile

              # ══════════════════════════════════════════════════
              # HOME PAGE – Terraform Docker Deployment
              # ══════════════════════════════════════════════════
              cat > /opt/webapp/index.html <<'HTML'
              <!DOCTYPE html>
              <html lang="en">
              <head>
                <meta charset="UTF-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <title>Terraform Docker Deployment</title>
                <style>
                  * { box-sizing: border-box; margin: 0; padding: 0; }
                  body {
                    font-family: 'Segoe UI', Arial, sans-serif;
                    min-height: 100vh;
                    display: grid;
                    place-items: center;
                    background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
                    color: #e2e8f0;
                  }
                  .card {
                    background: rgba(255, 255, 255, 0.06);
                    backdrop-filter: blur(12px);
                    border: 1px solid rgba(255, 255, 255, 0.12);
                    border-radius: 16px;
                    padding: 48px 40px;
                    width: min(520px, 92vw);
                    text-align: center;
                    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
                  }
                  .card h1 {
                    font-size: 2rem;
                    margin-bottom: 12px;
                    background: linear-gradient(90deg, #667eea, #764ba2);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                  }
                  .card p { color: #94a3b8; line-height: 1.6; }
                  .badge {
                    display: inline-block;
                    margin-top: 20px;
                    padding: 6px 16px;
                    border-radius: 999px;
                    font-size: 0.85rem;
                    font-weight: 600;
                    background: rgba(102, 126, 234, 0.15);
                    color: #667eea;
                    border: 1px solid rgba(102, 126, 234, 0.3);
                  }
                  .nav-link {
                    display: inline-block;
                    margin-top: 28px;
                    padding: 12px 32px;
                    border-radius: 12px;
                    font-size: 0.95rem;
                    font-weight: 600;
                    text-decoration: none;
                    color: #fff;
                    background: linear-gradient(135deg, #667eea, #764ba2);
                    transition: all 0.3s ease;
                    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
                  }
                  .nav-link:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
                  }
                </style>
              </head>
              <body>
                <main class="card">
                  <h1>Containerized Deployment</h1>
                  <p>This application is running inside a <strong>Docker container</strong>,
                     provisioned automatically using <strong>Terraform</strong> on AWS EC2.</p>
                  <span class="badge">Nginx &middot; Docker &middot; Terraform</span>
                  <br/>
                  <a href="/madhan-profile/" class="nav-link">View AutoServe Pro &rarr;</a>
                </main>
              </body>
              </html>
              HTML

              # ══════════════════════════════════════════════════
              # /madhan-profile – AutoServe Pro Consultancy Page
              # Images loaded from S3: ${var.s3_bucket_url}
              # ══════════════════════════════════════════════════
              cat > /opt/webapp/madhan-profile/index.html <<'PROFILE'
              <!DOCTYPE html>
              <html lang="en">
              <head>
                <meta charset="UTF-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <title>AutoServe Pro – Madhan's Consultancy Project</title>
                <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet" />
                <style>
                  :root {
                    --bg-primary: #0a0a1a;
                    --bg-card: rgba(255,255,255,0.04);
                    --border: rgba(255,255,255,0.08);
                    --text-primary: #e2e8f0;
                    --text-secondary: #94a3b8;
                    --accent: #667eea;
                    --accent2: #764ba2;
                    --success: #22c55e;
                  }
                  * { box-sizing: border-box; margin: 0; padding: 0; }
                  html { scroll-behavior: smooth; }
                  body {
                    font-family: 'Inter', 'Segoe UI', sans-serif;
                    background: var(--bg-primary);
                    color: var(--text-primary);
                    line-height: 1.7;
                    overflow-x: hidden;
                  }

                  /* ── Animated Background ── */
                  body::before {
                    content: '';
                    position: fixed;
                    top: 0; left: 0;
                    width: 100%; height: 100%;
                    background:
                      radial-gradient(ellipse at 20% 50%, rgba(102,126,234,0.08) 0%, transparent 50%),
                      radial-gradient(ellipse at 80% 20%, rgba(118,75,162,0.06) 0%, transparent 50%),
                      radial-gradient(ellipse at 50% 80%, rgba(34,197,94,0.04) 0%, transparent 50%);
                    pointer-events: none;
                    z-index: 0;
                  }

                  /* ── Navigation ── */
                  nav {
                    position: fixed;
                    top: 0; left: 0; right: 0;
                    z-index: 100;
                    padding: 16px 40px;
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    background: rgba(10,10,26,0.85);
                    backdrop-filter: blur(20px);
                    border-bottom: 1px solid var(--border);
                  }
                  nav .logo {
                    font-size: 1.3rem;
                    font-weight: 800;
                    background: linear-gradient(135deg, var(--accent), var(--accent2));
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                  }
                  nav .back-link {
                    color: var(--text-secondary);
                    text-decoration: none;
                    font-size: 0.9rem;
                    padding: 8px 20px;
                    border: 1px solid var(--border);
                    border-radius: 8px;
                    transition: all 0.3s;
                  }
                  nav .back-link:hover {
                    color: var(--accent);
                    border-color: var(--accent);
                  }

                  /* ── Hero Section ── */
                  .hero {
                    position: relative;
                    z-index: 1;
                    padding: 140px 40px 80px;
                    text-align: center;
                    max-width: 900px;
                    margin: 0 auto;
                  }
                  .hero-badge {
                    display: inline-block;
                    padding: 6px 18px;
                    border-radius: 999px;
                    font-size: 0.8rem;
                    font-weight: 600;
                    letter-spacing: 1px;
                    text-transform: uppercase;
                    background: rgba(34,197,94,0.1);
                    color: var(--success);
                    border: 1px solid rgba(34,197,94,0.2);
                    margin-bottom: 24px;
                  }
                  .hero h1 {
                    font-size: clamp(2.5rem, 5vw, 4rem);
                    font-weight: 900;
                    line-height: 1.1;
                    margin-bottom: 20px;
                    background: linear-gradient(135deg, #fff 0%, #667eea 50%, #764ba2 100%);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                  }
                  .hero p {
                    font-size: 1.15rem;
                    color: var(--text-secondary);
                    max-width: 650px;
                    margin: 0 auto;
                  }

                  /* ── Section ── */
                  section {
                    position: relative;
                    z-index: 1;
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 60px 40px;
                  }
                  .section-title {
                    font-size: 1.8rem;
                    font-weight: 800;
                    margin-bottom: 12px;
                    background: linear-gradient(90deg, var(--accent), var(--accent2));
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                    display: inline-block;
                  }
                  .section-subtitle {
                    color: var(--text-secondary);
                    margin-bottom: 40px;
                    font-size: 1.05rem;
                  }

                  /* ── About Grid ── */
                  .about-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
                    gap: 24px;
                    margin-top: 32px;
                  }
                  .about-card {
                    background: var(--bg-card);
                    border: 1px solid var(--border);
                    border-radius: 16px;
                    padding: 32px;
                    transition: all 0.3s;
                  }
                  .about-card:hover {
                    border-color: rgba(102,126,234,0.3);
                    transform: translateY(-4px);
                    box-shadow: 0 12px 40px rgba(102,126,234,0.1);
                  }
                  .about-card .icon {
                    font-size: 2rem;
                    margin-bottom: 16px;
                  }
                  .about-card h3 {
                    font-size: 1.1rem;
                    font-weight: 700;
                    margin-bottom: 8px;
                  }
                  .about-card p {
                    color: var(--text-secondary);
                    font-size: 0.95rem;
                  }

                  /* ── Tech Stack ── */
                  .tech-stack {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 12px;
                    margin-top: 24px;
                  }
                  .tech-tag {
                    padding: 8px 18px;
                    border-radius: 10px;
                    font-size: 0.85rem;
                    font-weight: 600;
                    background: rgba(102,126,234,0.1);
                    color: var(--accent);
                    border: 1px solid rgba(102,126,234,0.2);
                    transition: all 0.3s;
                  }
                  .tech-tag:hover {
                    background: rgba(102,126,234,0.2);
                    transform: scale(1.05);
                  }

                  /* ── Screenshot Gallery ── */
                  .gallery {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
                    gap: 24px;
                    margin-top: 32px;
                  }
                  .gallery-item {
                    position: relative;
                    border-radius: 16px;
                    overflow: hidden;
                    border: 1px solid var(--border);
                    transition: all 0.4s ease;
                    cursor: pointer;
                    aspect-ratio: 16/10;
                  }
                  .gallery-item:hover {
                    border-color: rgba(102,126,234,0.4);
                    transform: translateY(-6px);
                    box-shadow: 0 20px 60px rgba(102,126,234,0.15);
                  }
                  .gallery-item img {
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                    display: block;
                    transition: transform 0.4s ease;
                  }
                  .gallery-item:hover img {
                    transform: scale(1.03);
                  }
                  .gallery-caption {
                    position: absolute;
                    bottom: 0;
                    left: 0; right: 0;
                    padding: 20px;
                    background: linear-gradient(transparent, rgba(0,0,0,0.85));
                    opacity: 0;
                    transition: opacity 0.3s;
                  }
                  .gallery-item:hover .gallery-caption {
                    opacity: 1;
                  }
                  .gallery-caption h4 {
                    font-size: 0.95rem;
                    font-weight: 600;
                    margin-bottom: 4px;
                  }
                  .gallery-caption p {
                    font-size: 0.8rem;
                    color: var(--text-secondary);
                  }

                  /* ── Lightbox ── */
                  .lightbox {
                    display: none;
                    position: fixed;
                    top: 0; left: 0;
                    width: 100%; height: 100%;
                    background: rgba(0, 0, 0, 0.92);
                    z-index: 1000;
                    place-items: center;
                    cursor: zoom-out;
                    backdrop-filter: blur(10px);
                  }
                  .lightbox.active { display: grid; }
                  .lightbox img {
                    max-width: 90vw;
                    max-height: 90vh;
                    border-radius: 12px;
                    box-shadow: 0 0 60px rgba(102,126,234,0.3);
                  }
                  .lightbox-close {
                    position: absolute;
                    top: 24px; right: 32px;
                    font-size: 2rem;
                    color: #fff;
                    cursor: pointer;
                    background: none;
                    border: none;
                    opacity: 0.7;
                    transition: opacity 0.3s;
                  }
                  .lightbox-close:hover { opacity: 1; }

                  /* ── Footer ── */
                  footer {
                    position: relative;
                    z-index: 1;
                    text-align: center;
                    padding: 40px;
                    color: var(--text-secondary);
                    font-size: 0.85rem;
                    border-top: 1px solid var(--border);
                  }
                  footer a {
                    color: var(--accent);
                    text-decoration: none;
                  }

                  /* ── Responsive ── */
                  @media (max-width: 768px) {
                    nav { padding: 12px 20px; }
                    .hero { padding: 120px 20px 60px; }
                    section { padding: 40px 20px; }
                    .gallery { grid-template-columns: 1fr; }
                  }

                  /* ── Animations ── */
                  @keyframes fadeUp {
                    from { opacity: 0; transform: translateY(30px); }
                    to   { opacity: 1; transform: translateY(0); }
                  }
                  .animate {
                    animation: fadeUp 0.6s ease forwards;
                  }
                  .delay-1 { animation-delay: 0.1s; opacity: 0; }
                  .delay-2 { animation-delay: 0.2s; opacity: 0; }
                  .delay-3 { animation-delay: 0.3s; opacity: 0; }
                  .delay-4 { animation-delay: 0.4s; opacity: 0; }
                </style>
              </head>
              <body>

                <!-- Navigation -->
                <nav>
                  <span class="logo">Madhan &middot; Portfolio</span>
                  <a href="/" class="back-link">&larr; Back to Home</a>
                </nav>

                <!-- Hero -->
                <header class="hero">
                  <div class="hero-badge animate delay-1">Consultancy Project</div>
                  <h1 class="animate delay-2">AutoServe Pro</h1>
                  <p class="animate delay-3">A comprehensive <strong>Remote Device Monitoring &amp; Service Management Platform</strong>
                    built for JJ-Tech. Enabling technicians to scan networks, monitor device health in real-time,
                    manage service requests, generate reports, and track everything via audit logs.</p>
                </header>

                <!-- About Section -->
                <section>
                  <h2 class="section-title">About the Project</h2>
                  <p class="section-subtitle">AutoServe Pro is a full-stack desktop application designed to streamline IT service operations.</p>

                  <div class="about-grid">
                    <div class="about-card animate delay-1">
                      <div class="icon">📡</div>
                      <h3>Network Device Scanning</h3>
                      <p>Auto-detect devices on the network with real-time status monitoring — computers, mobile hotspots, and network devices.</p>
                    </div>
                    <div class="about-card animate delay-2">
                      <div class="icon">📊</div>
                      <h3>Live Health Monitoring</h3>
                      <p>Real-time CPU usage, RAM utilization, and battery status dashboards with interactive charts and visual indicators.</p>
                    </div>
                    <div class="about-card animate delay-3">
                      <div class="icon">🔧</div>
                      <h3>Service Request Management</h3>
                      <p>Create, track, and complete service requests with priority levels, status tracking, and device snapshots for each request.</p>
                    </div>
                    <div class="about-card animate delay-4">
                      <div class="icon">📄</div>
                      <h3>Report Generation &amp; Sharing</h3>
                      <p>Generate detailed PDF service reports with device info, execution summaries, and share directly via WhatsApp integration.</p>
                    </div>
                    <div class="about-card animate delay-1">
                      <div class="icon">📋</div>
                      <h3>Audit Logging</h3>
                      <p>Complete audit trail of all actions — logins, device registrations, service executions, and report generation with timestamps.</p>
                    </div>
                    <div class="about-card animate delay-2">
                      <div class="icon">🔐</div>
                      <h3>Secure Authentication</h3>
                      <p>Admin and Guest login modes with role-based access control. Guest mode provides read-only client access to device monitoring.</p>
                    </div>
                  </div>
                </section>

                <!-- Tech Stack -->
                <section>
                  <h2 class="section-title">Tech Stack</h2>
                  <p class="section-subtitle">Built with modern technologies for performance and reliability.</p>
                  <div class="tech-stack">
                    <span class="tech-tag">Electron.js</span>
                    <span class="tech-tag">Node.js</span>
                    <span class="tech-tag">Express</span>
                    <span class="tech-tag">SQLite</span>
                    <span class="tech-tag">Firebase</span>
                    <span class="tech-tag">HTML / CSS / JS</span>
                    <span class="tech-tag">Chart.js</span>
                    <span class="tech-tag">QR Code API</span>
                    <span class="tech-tag">PDFKit</span>
                    <span class="tech-tag">WhatsApp API</span>
                    <span class="tech-tag">Docker</span>
                    <span class="tech-tag">Terraform</span>
                    <span class="tech-tag">Jenkins CI/CD</span>
                    <span class="tech-tag">AWS EC2</span>
                    <span class="tech-tag">AWS S3</span>
                  </div>
                </section>

                <!-- Screenshots Gallery -->
                <section>
                  <h2 class="section-title">Application Screenshots</h2>
                  <p class="section-subtitle">Images served from AWS S3 bucket — connected to this EC2 instance via Terraform.</p>

                  <div class="gallery">
                    <div class="gallery-item" onclick="openLightbox(this)">
                      <img src="S3_URL_PLACEHOLDER/images/1.png" alt="Login Screen" loading="lazy" />
                      <div class="gallery-caption">
                        <h4>Login Screen</h4>
                        <p>Secure authentication with admin &amp; guest modes</p>
                      </div>
                    </div>
                    <div class="gallery-item" onclick="openLightbox(this)">
                      <img src="S3_URL_PLACEHOLDER/images/2.png" alt="Dashboard" loading="lazy" />
                      <div class="gallery-caption">
                        <h4>Dashboard</h4>
                        <p>Real-time device health monitoring with CPU, RAM &amp; battery stats</p>
                      </div>
                    </div>
                    <div class="gallery-item" onclick="openLightbox(this)">
                      <img src="S3_URL_PLACEHOLDER/images/3.png" alt="Service Management" loading="lazy" />
                      <div class="gallery-caption">
                        <h4>Service Management</h4>
                        <p>Track service requests with status, priority &amp; user assignments</p>
                      </div>
                    </div>
                    <div class="gallery-item" onclick="openLightbox(this)">
                      <img src="S3_URL_PLACEHOLDER/images/4.png" alt="Take Service" loading="lazy" />
                      <div class="gallery-caption">
                        <h4>Create Service Request</h4>
                        <p>Performance optimization, diagnostics &amp; more service types</p>
                      </div>
                    </div>
                    <div class="gallery-item" onclick="openLightbox(this)">
                      <img src="S3_URL_PLACEHOLDER/images/5.png" alt="Service Details" loading="lazy" />
                      <div class="gallery-caption">
                        <h4>Service Request Details</h4>
                        <p>Complete device snapshot with execution timeline</p>
                      </div>
                    </div>
                    <div class="gallery-item" onclick="openLightbox(this)">
                      <img src="S3_URL_PLACEHOLDER/images/6.png" alt="PDF Report" loading="lazy" />
                      <div class="gallery-caption">
                        <h4>Generated PDF Report</h4>
                        <p>Professional service reports with device info &amp; admin details</p>
                      </div>
                    </div>
                    <div class="gallery-item" onclick="openLightbox(this)">
                      <img src="S3_URL_PLACEHOLDER/images/7.png" alt="WhatsApp Share" loading="lazy" />
                      <div class="gallery-caption">
                        <h4>WhatsApp Integration</h4>
                        <p>Share service reports directly to customers via WhatsApp</p>
                      </div>
                    </div>
                    <div class="gallery-item" onclick="openLightbox(this)">
                      <img src="S3_URL_PLACEHOLDER/images/8.png" alt="Audit Logs" loading="lazy" />
                      <div class="gallery-caption">
                        <h4>Audit Logs</h4>
                        <p>Complete trail of all system actions with timestamps</p>
                      </div>
                    </div>
                    <div class="gallery-item" onclick="openLightbox(this)">
                      <img src="S3_URL_PLACEHOLDER/images/9.png" alt="Reports" loading="lazy" />
                      <div class="gallery-caption">
                        <h4>Reports Module</h4>
                        <p>Download &amp; share service reports with WhatsApp integration</p>
                      </div>
                    </div>
                  </div>
                </section>

                <!-- Footer -->
                <footer>
                  <p>&copy; 2026 Madhan &middot; AutoServe Pro &middot; Deployed with
                    <a href="/">Terraform + Docker + Jenkins</a> on AWS</p>
                </footer>

                <!-- Lightbox -->
                <div class="lightbox" id="lightbox" onclick="closeLightbox()">
                  <button class="lightbox-close">&times;</button>
                  <img id="lightbox-img" src="" alt="Full view" />
                </div>

                <script>
                  function openLightbox(el) {
                    const src = el.querySelector('img').src;
                    document.getElementById('lightbox-img').src = src;
                    document.getElementById('lightbox').classList.add('active');
                    document.body.style.overflow = 'hidden';
                  }
                  function closeLightbox() {
                    document.getElementById('lightbox').classList.remove('active');
                    document.body.style.overflow = '';
                  }
                  document.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape') closeLightbox();
                  });
                </script>
              </body>
              </html>
              PROFILE

              # ── Replace S3 URL placeholder with actual bucket URL ──
              sed -i "s|S3_URL_PLACEHOLDER|${var.s3_bucket_url}|g" /opt/webapp/madhan-profile/index.html

              # ── Write Nginx custom config ──
              cat > /opt/webapp/nginx.conf <<'NGINX'
              server {
                  listen 80;
                  server_name localhost;

                  location / {
                      root   /usr/share/nginx/html;
                      index  index.html;
                  }

                  location /madhan-profile/ {
                      alias /usr/share/nginx/html/madhan-profile/;
                      index index.html;
                  }

                  location /health {
                      access_log off;
                      return 200 'OK';
                      add_header Content-Type text/plain;
                  }
              }
              NGINX

              # ── Write Docker Compose file ──
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

              # ── Start the container ──
              cd /opt/webapp
              docker-compose up -d

              echo "=== Deployment complete ==="
              EOF

  tags = {
    Name        = "Terraform-DockerHost"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
