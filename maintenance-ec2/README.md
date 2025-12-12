# Saama Maintenance Page - EC2 Deployment

This package contains everything needed to deploy the Saama maintenance page on an AWS EC2 instance with Nginx, including comprehensive security hardening and optional Application Load Balancer setup.

## 📦 Package Contents

- `index.html` - Security-hardened HTML page
- `styles.css` - Stylesheet
- `script.js` - Auto-refresh functionality
- `saama_logo.svg` - Saama logo (colored)
- `saama_logo_white.svg` - Saama logo (white)
- `nginx.conf` - Nginx configuration with SSL/TLS and security headers
- `nginx-alb.conf` - Nginx configuration for use with Application Load Balancer
- `deploy.sh` - Automated deployment script
- `ALB_SETUP_GUIDE.md` - Complete guide for ALB + Target Group setup
- `README.md` - This file

## 🏗️ Deployment Options

### Option 1: Direct EC2 with SSL (Simple)
- Single EC2 instance
- SSL handled by Nginx
- Use `nginx.conf`
- Cost: ~$10-15/month

### Option 2: EC2 Behind Application Load Balancer (Recommended for Production)
- Multiple EC2 instances for high availability
- SSL handled by ALB
- Auto-scaling capable
- Use `nginx-alb.conf`
- **See [ALB_SETUP_GUIDE.md](ALB_SETUP_GUIDE.md) for complete instructions**
- Cost: ~$32-40/month

## 🔒 Security Features

### Built-in Security
- ✅ **HTTPS Enforcement** - Automatic HTTP to HTTPS redirect
- ✅ **TLS 1.2+ Only** - Modern encryption protocols
- ✅ **Security Headers**:
  - Content Security Policy (CSP)
  - X-Frame-Options (Clickjacking protection)
  - X-Content-Type-Options (MIME sniffing protection)
  - X-XSS-Protection
  - Strict-Transport-Security (HSTS)
  - Referrer-Policy
  - Permissions-Policy
- ✅ **Rate Limiting** - 10 requests/second per IP
- ✅ **Hidden File Protection** - Blocks access to .git, .env, etc.
- ✅ **Server Token Hiding** - Nginx version hidden
- ✅ **Input Sanitization** - No user inputs, static content only

## 📋 Prerequisites

- AWS EC2 instance (Ubuntu 20.04+, Amazon Linux 2, or Amazon Linux 2023)
- Root or sudo access
- SSL/TLS certificate for your domain
- Domain DNS configured to point to EC2 instance
- EC2 Security Group configured to allow ports 22, 80, and 443

## 🚀 Quick Deployment

### Option 1: Automated Deployment (Recommended)

**The deployment script automatically detects your OS (Ubuntu, Debian, or Amazon Linux) and uses the appropriate package manager.**

#### For Ubuntu/Debian:
```bash
# 1. Upload all files to EC2
scp -i your-key.pem * ubuntu@your-ec2-ip:/home/ubuntu/maintenance/

# 2. SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# 3. Run deployment script
cd /home/ubuntu/maintenance
sudo ./deploy.sh
```

#### For Amazon Linux:
```bash
# 1. Upload all files to EC2
scp -i your-key.pem * ec2-user@your-ec2-ip:/home/ec2-user/maintenance/

# 2. SSH into EC2
ssh -i your-key.pem ec2-user@your-ec2-ip

# 3. Run deployment script
cd /home/ec2-user/maintenance
sudo ./deploy.sh
```

### Option 2: Manual Deployment

#### Ubuntu/Debian:
```bash
# 1. Install Nginx
sudo apt-get update
sudo apt-get install -y nginx

# 2. Create web directory
sudo mkdir -p /var/www/saama-maintenance

# 3. Copy files
sudo cp index.html styles.css script.js saama_logo*.svg /var/www/saama-maintenance/

# 4. Set permissions
sudo chown -R www-data:www-data /var/www/saama-maintenance
sudo chmod 755 /var/www/saama-maintenance
sudo chmod 644 /var/www/saama-maintenance/*

# 5. Configure Nginx
sudo cp nginx.conf /etc/nginx/sites-available/saama-maintenance
sudo ln -s /etc/nginx/sites-available/saama-maintenance /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 6. Update SSL certificate paths in nginx.conf
sudo nano /etc/nginx/sites-available/saama-maintenance
# Update these lines:
#   ssl_certificate /path/to/your/certificate.crt;
#   ssl_certificate_key /path/to/your/private.key;

# 7. Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

#### Amazon Linux:
```bash
# 1. Install Nginx
sudo yum update -y
sudo yum install -y nginx

# 2. Create web directory
sudo mkdir -p /var/www/saama-maintenance

# 3. Copy files
sudo cp index.html styles.css script.js saama_logo*.svg /var/www/saama-maintenance/

# 4. Set permissions
sudo chown -R nginx:nginx /var/www/saama-maintenance
sudo chmod 755 /var/www/saama-maintenance
sudo chmod 644 /var/www/saama-maintenance/*

# 5. Configure Nginx
sudo cp nginx.conf /etc/nginx/conf.d/saama-maintenance.conf

# 6. Update SSL certificate paths
sudo nano /etc/nginx/conf.d/saama-maintenance.conf
# Update these lines:
#   ssl_certificate /path/to/your/certificate.crt;
#   ssl_certificate_key /path/to/your/private.key;

# 7. Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

## 🔐 SSL Certificate Setup

### Using Let's Encrypt (Free)

```bash
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d signin.saama.cloud

# Auto-renewal is configured automatically
```

### Using Custom Certificate

```bash
# Copy your certificate files
sudo cp your-certificate.crt /etc/ssl/certs/saama.crt
sudo cp your-private-key.key /etc/ssl/private/saama.key

# Set permissions
sudo chmod 644 /etc/ssl/certs/saama.crt
sudo chmod 600 /etc/ssl/private/saama.key

# Update nginx.conf with correct paths
```

## 🔧 Configuration

### Update Domain Name

Edit `/etc/nginx/sites-available/saama-maintenance`:
```nginx
server_name signin.saama.cloud;  # Change to your domain
```

### Adjust Rate Limiting

Edit the rate limit in nginx.conf:
```nginx
limit_req_zone $binary_remote_addr zone=maintenance:10m rate=10r/s;
```

### Change Auto-Refresh Interval

Edit `script.js`:
```javascript
const AUTO_REFRESH_INTERVAL = 5 * 60 * 1000; // 5 minutes
```

## 🧪 Testing

```bash
# Test Nginx configuration
sudo nginx -t

# Check if Nginx is running
sudo systemctl status nginx

# Test HTTP to HTTPS redirect
curl -I http://signin.saama.cloud

# Test security headers
curl -I https://signin.saama.cloud

# Check logs
sudo tail -f /var/log/nginx/saama-maintenance-access.log
sudo tail -f /var/log/nginx/saama-maintenance-error.log
```

## 🛡️ Security Checklist

- [ ] SSL/TLS certificate installed and valid
- [ ] HTTPS enforcement working (HTTP redirects to HTTPS)
- [ ] Security headers present in response
- [ ] Rate limiting configured
- [ ] Server tokens disabled
- [ ] Hidden files blocked
- [ ] Firewall configured (allow only 80, 443, and SSH)
- [ ] EC2 security group configured properly
- [ ] Regular security updates enabled

## 🔥 Firewall Configuration

```bash
# Using UFW (Ubuntu)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Using iptables
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -j DROP
```

## 📊 Monitoring

```bash
# View access logs
sudo tail -f /var/log/nginx/saama-maintenance-access.log

# View error logs
sudo tail -f /var/log/nginx/saama-maintenance-error.log

# Check Nginx status
sudo systemctl status nginx

# Monitor connections
sudo netstat -tuln | grep :443
```

## 🔄 Updating Content

```bash
# 1. Upload new files
scp -i your-key.pem index.html ubuntu@your-ec2-ip:/tmp/

# 2. Replace files
sudo cp /tmp/index.html /var/www/saama-maintenance/

# 3. Set permissions
sudo chown www-data:www-data /var/www/saama-maintenance/index.html
sudo chmod 644 /var/www/saama-maintenance/index.html

# No need to restart Nginx for content changes
```

## ❌ Troubleshooting

### Nginx won't start
```bash
# Check configuration
sudo nginx -t

# Check logs
sudo journalctl -u nginx -n 50
```

### 502 Bad Gateway
```bash
# Check if Nginx is running
sudo systemctl status nginx

# Restart Nginx
sudo systemctl restart nginx
```

### SSL Certificate Issues
```bash
# Verify certificate
sudo openssl x509 -in /etc/ssl/certs/saama.crt -text -noout

# Check certificate expiry
sudo openssl x509 -in /etc/ssl/certs/saama.crt -noout -dates
```

## 📞 Support

For issues or questions, contact: support@saama.com

---

**Version**: 1.0.0  
**Last Updated**: December 12, 2025
