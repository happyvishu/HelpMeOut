#!/bin/bash

# Saama Maintenance Page - EC2 Deployment Script
# This script deploys the maintenance page on an EC2 instance with Nginx
# Supports: Ubuntu, Debian, Amazon Linux 2, Amazon Linux 2023

set -e

echo "=========================================="
echo "Saama Maintenance Page - EC2 Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo -e "${RED}Cannot detect OS. This script supports Ubuntu, Debian, and Amazon Linux.${NC}"
    exit 1
fi

echo -e "${BLUE}Detected OS: $OS $VERSION${NC}"
echo ""

# Install Nginx based on OS
echo -e "${GREEN}Step 1: Installing Nginx...${NC}"
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    apt-get update
    apt-get install -y nginx
elif [[ "$OS" == "amzn" ]]; then
    # Amazon Linux
    yum update -y
    yum install -y nginx
else
    echo -e "${RED}Unsupported OS: $OS${NC}"
    echo "This script supports Ubuntu, Debian, and Amazon Linux."
    exit 1
fi

echo -e "${GREEN}Step 2: Creating web directory...${NC}"
mkdir -p /var/www/saama-maintenance
chmod 755 /var/www/saama-maintenance

echo -e "${GREEN}Step 3: Copying files...${NC}"
cp index.html /var/www/saama-maintenance/
cp styles.css /var/www/saama-maintenance/
cp script.js /var/www/saama-maintenance/
cp saama_logo.svg /var/www/saama-maintenance/
cp saama_logo_white.svg /var/www/saama-maintenance/

echo -e "${GREEN}Step 4: Setting permissions...${NC}"
chown -R nginx:nginx /var/www/saama-maintenance
find /var/www/saama-maintenance -type f -exec chmod 644 {} \;
find /var/www/saama-maintenance -type d -exec chmod 755 {} \;

echo -e "${GREEN}Step 5: Configuring Nginx...${NC}"
if [[ "$OS" == "amzn" ]]; then
    # Amazon Linux uses different nginx config structure
    cp nginx.conf /etc/nginx/conf.d/saama-maintenance.conf
else
    # Ubuntu/Debian
    cp nginx.conf /etc/nginx/sites-available/saama-maintenance
    ln -sf /etc/nginx/sites-available/saama-maintenance /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
fi

echo -e "${YELLOW}Note: Please update SSL certificate paths in the Nginx configuration${NC}"
if [[ "$OS" == "amzn" ]]; then
    echo -e "${YELLOW}Configuration file: /etc/nginx/conf.d/saama-maintenance.conf${NC}"
else
    echo -e "${YELLOW}Configuration file: /etc/nginx/sites-available/saama-maintenance${NC}"
fi
echo -e "${YELLOW}Lines to update:${NC}"
echo -e "  ssl_certificate /etc/ssl/certs/saama.crt;"
echo -e "  ssl_certificate_key /etc/ssl/private/saama.key;"
echo ""

echo -e "${GREEN}Step 6: Testing Nginx configuration...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Step 7: Starting Nginx...${NC}"
    systemctl restart nginx
    systemctl enable nginx
    
    echo ""
    echo -e "${GREEN}=========================================="
    echo "Deployment Complete!"
    echo "==========================================${NC}"
    echo ""
    echo "OS: $OS $VERSION"
    echo ""
    echo "Next steps:"
    echo "1. Update SSL certificate paths in Nginx configuration"
    if [[ "$OS" == "amzn" ]]; then
        echo "   File: /etc/nginx/conf.d/saama-maintenance.conf"
    else
        echo "   File: /etc/nginx/sites-available/saama-maintenance"
    fi
    echo "2. Reload Nginx: systemctl reload nginx"
    echo "3. Configure your domain DNS to point to this EC2 instance"
    echo "4. Configure Security Group to allow ports 80 and 443"
    echo "5. Test the site: https://signin.saama.cloud"
    echo ""
    echo "Security features enabled:"
    echo "  ✓ HTTPS enforcement"
    echo "  ✓ Security headers (CSP, XSS, Clickjacking protection)"
    echo "  ✓ Rate limiting (10 requests/second)"
    echo "  ✓ Hidden file protection"
    echo "  ✓ TLS 1.2+ only"
    echo ""
    echo "Firewall configuration:"
    if [[ "$OS" == "amzn" ]]; then
        echo "  Amazon Linux uses Security Groups - configure in AWS Console"
    else
        echo "  Run: sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw enable"
    fi
    echo ""
else
    echo -e "${RED}Nginx configuration test failed. Please check the configuration.${NC}"
    exit 1
fi
