# Saama Maintenance Page - S3 + CloudFront Deployment

This package contains everything needed to deploy the Saama maintenance page on AWS S3 with CloudFront CDN, including comprehensive security hardening.

## 📦 Package Contents

- `index.html` - Main HTML page
- `styles.css` - Stylesheet
- `script.js` - Auto-refresh functionality
- `saama_logo.svg` - Saama logo (colored)
- `saama_logo_white.svg` - Saama logo (white)
- `bucket-policy.json` - S3 bucket policy with HTTPS enforcement
- `cloudfront-config.json` - CloudFront distribution configuration
- `security-headers-policy.json` - CloudFront security headers policy
- `deploy.sh` - Automated deployment script
- `README.md` - This file

## 🔒 Security Features

### Built-in Security
- ✅ **HTTPS Enforcement** - Bucket policy denies non-HTTPS requests
- ✅ **CloudFront CDN** - Global edge caching with DDoS protection
- ✅ **TLS 1.2+ Only** - Modern encryption protocols
- ✅ **Security Headers** via CloudFront:
  - Content Security Policy (CSP)
  - Strict-Transport-Security (HSTS)
  - X-Frame-Options (Clickjacking protection)
  - X-Content-Type-Options (MIME sniffing protection)
  - X-XSS-Protection
  - Referrer-Policy
  - Permissions-Policy
- ✅ **Server-Side Encryption** - AES256 encryption at rest
- ✅ **Bucket Versioning** - File version history
- ✅ **Origin Access Identity** - Restrict S3 access to CloudFront only
- ✅ **WAF Integration Ready** - Can add AWS WAF for additional protection

## 📋 Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Domain name (e.g., signin.saama.cloud)
- SSL/TLS certificate in AWS Certificate Manager (ACM) in us-east-1 region

## 🚀 Quick Deployment

### Step 1: Deploy to S3

```bash
# Run the automated deployment script
./deploy.sh

# When prompted, enter your bucket name
# Example: saama-maintenance-signin
```

### Step 2: Create SSL Certificate (if not already done)

```bash
# Request certificate in ACM (must be in us-east-1 for CloudFront)
aws acm request-certificate \
    --domain-name signin.saama.cloud \
    --validation-method DNS \
    --region us-east-1

# Follow the email or DNS validation process
```

### Step 3: Create CloudFront Distribution

#### Option A: Using AWS Console (Recommended)

1. Go to CloudFront in AWS Console
2. Click "Create Distribution"
3. Configure:
   - **Origin Domain**: Select your S3 bucket
   - **Origin Access**: Legacy access identities → Create new OAI
   - **Viewer Protocol Policy**: Redirect HTTP to HTTPS
   - **Allowed HTTP Methods**: GET, HEAD
   - **Cache Policy**: CachingOptimized
   - **Alternate Domain Names (CNAMEs)**: signin.saama.cloud
   - **Custom SSL Certificate**: Select your ACM certificate
   - **Supported HTTP Versions**: HTTP/2 and HTTP/3
   - **Default Root Object**: index.html
4. Create Response Headers Policy:
   - Use the configuration from `security-headers-policy.json`
5. Attach the headers policy to the distribution

#### Option B: Using AWS CLI

```bash
# 1. Create security headers policy
aws cloudfront create-response-headers-policy \
    --response-headers-policy-config file://security-headers-policy.json \
    --region us-east-1

# Note the policy ID from the response

# 2. Update cloudfront-config.json with:
#    - Your bucket name
#    - Your ACM certificate ARN
#    - The security headers policy ID

# 3. Create distribution
aws cloudfront create-distribution \
    --distribution-config file://cloudfront-config.json
```

### Step 4: Update DNS

```bash
# Get CloudFront domain name
aws cloudfront list-distributions \
    --query "DistributionList.Items[?Aliases.Items[?contains(@, 'signin.saama.cloud')]].DomainName" \
    --output text

# Create CNAME record in your DNS:
# Type: CNAME
# Name: signin
# Value: d1234567890.cloudfront.net (your CloudFront domain)
# TTL: 300
```

### Step 5: Test

```bash
# Test HTTPS
curl -I https://signin.saama.cloud

# Verify security headers
curl -I https://signin.saama.cloud | grep -E "(X-Frame|X-Content|Strict-Transport|Content-Security)"
```

## 🔧 Configuration

### Update Bucket Name

Edit `bucket-policy.json` and `cloudfront-config.json`:
```json
"arn:aws:s3:::YOUR-BUCKET-NAME/*"
```

### Update Domain Name

Edit `cloudfront-config.json`:
```json
"Aliases": {
  "Items": ["signin.saama.cloud"]
}
```

### Update SSL Certificate

Edit `cloudfront-config.json`:
```json
"ACMCertificateArn": "arn:aws:acm:us-east-1:ACCOUNT-ID:certificate/CERTIFICATE-ID"
```

## 🔄 Updating Content

```bash
# 1. Update files locally
# Edit index.html, styles.css, etc.

# 2. Upload to S3
aws s3 sync . s3://YOUR-BUCKET-NAME \
    --exclude "*.sh" \
    --exclude "*.json" \
    --exclude "*.md" \
    --cache-control "public, max-age=3600"

# 3. Invalidate CloudFront cache
aws cloudfront create-invalidation \
    --distribution-id YOUR-DISTRIBUTION-ID \
    --paths "/*"
```

## 🛡️ Advanced Security (Optional)

### Add AWS WAF

```bash
# Create WAF Web ACL
aws wafv2 create-web-acl \
    --name saama-maintenance-waf \
    --scope CLOUDFRONT \
    --default-action Allow={} \
    --rules file://waf-rules.json \
    --region us-east-1

# Associate with CloudFront
aws cloudfront update-distribution \
    --id YOUR-DISTRIBUTION-ID \
    --web-acl-id YOUR-WAF-ACL-ARN
```

### Enable CloudFront Access Logs

```bash
# Create logging bucket
aws s3 mb s3://saama-maintenance-logs

# Update CloudFront distribution to enable logging
aws cloudfront update-distribution \
    --id YOUR-DISTRIBUTION-ID \
    --logging-config Enabled=true,IncludeCookies=false,Bucket=saama-maintenance-logs.s3.amazonaws.com,Prefix=cloudfront/
```

### Add Origin Access Identity (OAI)

```bash
# Create OAI
aws cloudfront create-cloud-front-origin-access-identity \
    --cloud-front-origin-access-identity-config CallerReference=saama-maintenance,Comment="OAI for Saama maintenance"

# Update S3 bucket policy to allow only CloudFront
# See bucket-policy-with-oai.json example
```

## 📊 Monitoring

### CloudWatch Metrics

```bash
# View CloudFront metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/CloudFront \
    --metric-name Requests \
    --dimensions Name=DistributionId,Value=YOUR-DISTRIBUTION-ID \
    --start-time 2025-12-12T00:00:00Z \
    --end-time 2025-12-12T23:59:59Z \
    --period 3600 \
    --statistics Sum
```

### View Logs

```bash
# Download CloudFront logs
aws s3 sync s3://saama-maintenance-logs/cloudfront/ ./logs/

# Analyze logs
zcat logs/*.gz | grep "signin.saama.cloud"
```

## 💰 Cost Optimization

### Estimated Monthly Costs (Low Traffic)
- S3 Storage: $0.023/GB (~$0.01 for this site)
- S3 Requests: $0.0004/1000 requests (~$0.01)
- CloudFront: $0.085/GB transfer (~$0.50 for 5GB)
- **Total: ~$1-2/month** for low traffic

### Cost Saving Tips
1. Use CloudFront caching to reduce S3 requests
2. Enable compression in CloudFront
3. Use appropriate cache TTLs
4. Consider CloudFront price class (PriceClass_100 for US/Europe only)

## 🧪 Testing Checklist

- [ ] Site loads via HTTPS
- [ ] HTTP redirects to HTTPS
- [ ] Security headers present in response
- [ ] SSL certificate valid
- [ ] Custom domain working
- [ ] Auto-refresh working (5 minutes)
- [ ] Logo displays correctly
- [ ] Responsive on mobile
- [ ] CloudFront caching working
- [ ] Error pages redirect to index.html

## ❌ Troubleshooting

### Site not loading
```bash
# Check distribution status
aws cloudfront get-distribution --id YOUR-DISTRIBUTION-ID \
    --query 'Distribution.Status'

# Wait for "Deployed" status
```

### SSL Certificate Error
```bash
# Verify certificate is in us-east-1
aws acm list-certificates --region us-east-1

# Check certificate validation status
aws acm describe-certificate \
    --certificate-arn YOUR-CERT-ARN \
    --region us-east-1
```

### 403 Forbidden Error
```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket YOUR-BUCKET-NAME

# Verify CloudFront has access
aws s3api get-bucket-policy-status --bucket YOUR-BUCKET-NAME
```

### Cache Not Updating
```bash
# Invalidate CloudFront cache
aws cloudfront create-invalidation \
    --distribution-id YOUR-DISTRIBUTION-ID \
    --paths "/*"
```

## 🔐 Security Best Practices

1. ✅ Always use HTTPS
2. ✅ Enable CloudFront access logs
3. ✅ Use Origin Access Identity (OAI)
4. ✅ Enable S3 bucket versioning
5. ✅ Enable S3 encryption at rest
6. ✅ Use AWS WAF for additional protection
7. ✅ Monitor CloudWatch metrics
8. ✅ Set up CloudWatch alarms for anomalies
9. ✅ Regularly review access logs
10. ✅ Keep SSL certificates up to date

## 📞 Support

For issues or questions, contact: support@saama.com

---

**Version**: 1.0.0  
**Last Updated**: December 12, 2025  
**Deployment Method**: S3 + CloudFront
