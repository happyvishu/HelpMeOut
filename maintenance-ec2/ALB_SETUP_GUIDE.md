# AWS Application Load Balancer Setup Guide

This guide shows how to deploy the Saama maintenance page on EC2 instances behind an Application Load Balancer (ALB) with a Target Group for high availability and scalability.

## Architecture Overview

```
Internet → ALB (HTTPS) → Target Group → EC2 Instances (HTTP)
                                      ↓
                                   Nginx serving maintenance page
```

## Benefits of Using ALB

- ✅ **High Availability** - Distribute traffic across multiple EC2 instances
- ✅ **SSL Termination** - Handle SSL/TLS at the load balancer level
- ✅ **Health Checks** - Automatic failover if an instance becomes unhealthy
- ✅ **Scalability** - Easy to add/remove instances
- ✅ **DDoS Protection** - AWS Shield Standard included
- ✅ **Cost Effective** - Share SSL certificate across instances

---

## Prerequisites

- ✅ EC2 instances deployed with maintenance page (use `deploy.sh`)
- ✅ VPC with at least 2 subnets in different Availability Zones
- ✅ SSL/TLS certificate in AWS Certificate Manager (ACM)
- ✅ Domain name (signin.saama.cloud)

---

## Step 1: Deploy Maintenance Page on EC2 Instances

First, deploy the maintenance page on your EC2 instance(s):

```bash
# SSH into EC2
ssh -i your-key.pem ec2-user@your-ec2-ip

# Upload and deploy
cd /home/ec2-user/maintenance
sudo ./deploy.sh
```

**Important**: When using ALB, you can skip SSL configuration on Nginx since ALB will handle SSL termination.

---

## Step 2: Create Target Group

### Using AWS Console:

1. Go to **EC2 Console** → **Target Groups**
2. Click **Create target group**
3. Configure:
   - **Target type**: Instances
   - **Target group name**: `saama-maintenance-tg`
   - **Protocol**: HTTP
   - **Port**: 80
   - **VPC**: Select your VPC
   - **Protocol version**: HTTP1
   
4. **Health checks**:
   - **Health check protocol**: HTTP
   - **Health check path**: `/index.html`
   - **Healthy threshold**: 2
   - **Unhealthy threshold**: 2
   - **Timeout**: 5 seconds
   - **Interval**: 30 seconds
   - **Success codes**: 200

5. Click **Next**
6. **Register targets**:
   - Select your EC2 instance(s)
   - Port: 80
   - Click **Include as pending below**
7. Click **Create target group**

### Using AWS CLI:

```bash
# Create target group
aws elbv2 create-target-group \
    --name saama-maintenance-tg \
    --protocol HTTP \
    --port 80 \
    --vpc-id vpc-xxxxxxxxx \
    --health-check-protocol HTTP \
    --health-check-path /index.html \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 2 \
    --matcher HttpCode=200

# Register EC2 instances
aws elbv2 register-targets \
    --target-group-arn arn:aws:elasticloadbalancing:region:account-id:targetgroup/saama-maintenance-tg/xxxxx \
    --targets Id=i-xxxxxxxxx Id=i-yyyyyyyyy
```

---

## Step 3: Create Application Load Balancer

### Using AWS Console:

1. Go to **EC2 Console** → **Load Balancers**
2. Click **Create Load Balancer**
3. Select **Application Load Balancer**
4. Configure:
   - **Name**: `saama-maintenance-alb`
   - **Scheme**: Internet-facing
   - **IP address type**: IPv4
   
5. **Network mapping**:
   - **VPC**: Select your VPC
   - **Mappings**: Select at least 2 Availability Zones
   - Select public subnets

6. **Security groups**:
   - Create or select a security group with:
     - Inbound: HTTP (80) from 0.0.0.0/0
     - Inbound: HTTPS (443) from 0.0.0.0/0
     - Outbound: All traffic

7. **Listeners and routing**:
   
   **HTTP Listener (Port 80)**:
   - Protocol: HTTP
   - Port: 80
   - Default action: Redirect to HTTPS
   - Status code: 301
   
   **HTTPS Listener (Port 443)**:
   - Protocol: HTTPS
   - Port: 443
   - Default action: Forward to `saama-maintenance-tg`
   - SSL certificate: Select from ACM

8. Click **Create load balancer**

### Using AWS CLI:

```bash
# Create load balancer
aws elbv2 create-load-balancer \
    --name saama-maintenance-alb \
    --subnets subnet-xxxxxxxx subnet-yyyyyyyy \
    --security-groups sg-xxxxxxxxx \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4

# Create HTTP listener (redirect to HTTPS)
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:region:account-id:loadbalancer/app/saama-maintenance-alb/xxxxx \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'

# Create HTTPS listener
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:region:account-id:loadbalancer/app/saama-maintenance-alb/xxxxx \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=arn:aws:acm:region:account-id:certificate/xxxxx \
    --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:account-id:targetgroup/saama-maintenance-tg/xxxxx
```

---

## Step 4: Configure Security Groups

### ALB Security Group

**Inbound Rules**:
```
Type        Protocol    Port    Source          Description
HTTP        TCP         80      0.0.0.0/0       Allow HTTP from internet
HTTPS       TCP         443     0.0.0.0/0       Allow HTTPS from internet
```

**Outbound Rules**:
```
Type        Protocol    Port    Destination     Description
HTTP        TCP         80      EC2-SG          Forward to EC2 instances
```

### EC2 Security Group

**Inbound Rules**:
```
Type        Protocol    Port    Source          Description
HTTP        TCP         80      ALB-SG          Allow from ALB only
SSH         TCP         22      Your-IP         SSH access
```

**Outbound Rules**:
```
Type        Protocol    Port    Destination     Description
All         All         All     0.0.0.0/0       Allow all outbound
```

---

## Step 5: Update DNS

Point your domain to the ALB:

```bash
# Get ALB DNS name
aws elbv2 describe-load-balancers \
    --names saama-maintenance-alb \
    --query 'LoadBalancers[0].DNSName' \
    --output text
```

**Create DNS Record**:
- Type: CNAME (or A with Alias for Route 53)
- Name: signin
- Value: saama-maintenance-alb-xxxxxxxxx.region.elb.amazonaws.com
- TTL: 300

**For Route 53 (Recommended)**:
1. Go to Route 53 → Hosted Zones
2. Select your domain
3. Create Record:
   - Record name: signin
   - Record type: A
   - Alias: Yes
   - Route traffic to: Alias to Application Load Balancer
   - Region: Select your region
   - Load balancer: Select `saama-maintenance-alb`

---

## Step 6: SSL Certificate Setup

### Using AWS Certificate Manager (ACM):

```bash
# Request certificate
aws acm request-certificate \
    --domain-name signin.saama.cloud \
    --validation-method DNS \
    --region us-east-1

# Validate via DNS (follow ACM console instructions)
# Once validated, attach to ALB HTTPS listener
```

---

## Step 7: Modify Nginx Configuration for ALB

Since ALB handles SSL, update Nginx to only listen on HTTP:

**Edit `/etc/nginx/conf.d/saama-maintenance.conf` (Amazon Linux)**:
```nginx
server {
    listen 80;
    server_name signin.saama.cloud;
    
    root /var/www/saama-maintenance;
    index index.html;
    
    # Security headers (ALB will add more)
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

**Reload Nginx**:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## Step 8: Testing

### Test Health Checks
```bash
# Check target health
aws elbv2 describe-target-health \
    --target-group-arn arn:aws:elasticloadbalancing:region:account-id:targetgroup/saama-maintenance-tg/xxxxx
```

### Test Load Balancer
```bash
# Test HTTP redirect
curl -I http://signin.saama.cloud

# Test HTTPS
curl -I https://signin.saama.cloud

# Verify security headers
curl -I https://signin.saama.cloud | grep -E "(X-Frame|X-Content|Strict-Transport)"
```

---

## Step 9: Enable Access Logs (Optional)

```bash
# Create S3 bucket for logs
aws s3 mb s3://saama-alb-logs

# Enable access logs
aws elbv2 modify-load-balancer-attributes \
    --load-balancer-arn arn:aws:elasticloadbalancing:region:account-id:loadbalancer/app/saama-maintenance-alb/xxxxx \
    --attributes Key=access_logs.s3.enabled,Value=true Key=access_logs.s3.bucket,Value=saama-alb-logs
```

---

## Auto Scaling (Optional)

For automatic scaling based on traffic:

```bash
# Create launch template
aws ec2 create-launch-template \
    --launch-template-name saama-maintenance-lt \
    --version-description "Maintenance page template" \
    --launch-template-data '{
        "ImageId": "ami-xxxxxxxxx",
        "InstanceType": "t3.micro",
        "KeyName": "your-key",
        "SecurityGroupIds": ["sg-xxxxxxxxx"],
        "UserData": "base64-encoded-startup-script"
    }'

# Create Auto Scaling group
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name saama-maintenance-asg \
    --launch-template LaunchTemplateName=saama-maintenance-lt \
    --min-size 2 \
    --max-size 4 \
    --desired-capacity 2 \
    --target-group-arns arn:aws:elasticloadbalancing:region:account-id:targetgroup/saama-maintenance-tg/xxxxx \
    --vpc-zone-identifier "subnet-xxxxxxxx,subnet-yyyyyyyy"
```

---

## Monitoring

### CloudWatch Metrics

Monitor these ALB metrics:
- `TargetResponseTime`
- `RequestCount`
- `HealthyHostCount`
- `UnHealthyHostCount`
- `HTTPCode_Target_2XX_Count`
- `HTTPCode_ELB_5XX_Count`

### Set Up Alarms

```bash
# Alarm for unhealthy targets
aws cloudwatch put-metric-alarm \
    --alarm-name saama-maintenance-unhealthy-targets \
    --alarm-description "Alert when targets are unhealthy" \
    --metric-name UnHealthyHostCount \
    --namespace AWS/ApplicationELB \
    --statistic Average \
    --period 60 \
    --evaluation-periods 2 \
    --threshold 1 \
    --comparison-operator GreaterThanThreshold
```

---

## Cost Estimate

**With ALB** (Monthly):
- ALB: ~$16-20/month
- EC2 (t3.micro x2): ~$15/month
- Data transfer: ~$1-5/month
- **Total**: ~$32-40/month

---

## Troubleshooting

### Targets Unhealthy
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn YOUR_TG_ARN

# Check Nginx is running
ssh ec2-user@instance-ip
sudo systemctl status nginx

# Check health check endpoint
curl http://localhost/health
```

### 502 Bad Gateway
- Check EC2 security group allows traffic from ALB
- Verify Nginx is listening on port 80
- Check target group health check settings

### SSL Certificate Issues
- Ensure certificate is in the same region as ALB
- Verify certificate is validated in ACM
- Check certificate covers your domain

---

## Security Best Practices

- ✅ Use ALB security group to restrict EC2 access
- ✅ Enable access logs for audit trail
- ✅ Use AWS WAF with ALB for additional protection
- ✅ Enable deletion protection on ALB
- ✅ Use multiple Availability Zones
- ✅ Implement Auto Scaling for redundancy
- ✅ Regular security group audits

---

**Version**: 1.0.0  
**Last Updated**: December 12, 2025
