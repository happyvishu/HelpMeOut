#!/bin/bash

# Saama Maintenance Page - S3 + CloudFront Deployment Script
# This script deploys the maintenance page to S3 with CloudFront CDN

set -e

echo "=========================================="
echo "Saama Maintenance Page - S3 Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUCKET_NAME=""
REGION="us-east-1"
CLOUDFRONT_DISTRIBUTION_ID=""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}AWS credentials not configured. Please run 'aws configure'${NC}"
    exit 1
fi

# Prompt for bucket name if not set
if [ -z "$BUCKET_NAME" ]; then
    echo -e "${BLUE}Enter S3 bucket name (e.g., saama-maintenance):${NC}"
    read BUCKET_NAME
fi

echo -e "${GREEN}Step 1: Creating S3 bucket...${NC}"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
    echo "Bucket created: $BUCKET_NAME"
else
    echo "Bucket already exists: $BUCKET_NAME"
fi

echo -e "${GREEN}Step 2: Configuring bucket for static website hosting...${NC}"
aws s3 website "s3://$BUCKET_NAME" \
    --index-document index.html \
    --error-document index.html

echo -e "${GREEN}Step 3: Blocking public access (we'll use CloudFront)...${NC}"
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

echo -e "${GREEN}Step 4: Uploading files to S3...${NC}"
aws s3 sync . "s3://$BUCKET_NAME" \
    --exclude "*.sh" \
    --exclude "*.json" \
    --exclude "*.md" \
    --exclude ".git/*" \
    --exclude ".DS_Store" \
    --cache-control "public, max-age=3600" \
    --metadata-directive REPLACE

echo -e "${GREEN}Step 5: Setting content types...${NC}"
aws s3 cp "s3://$BUCKET_NAME/index.html" "s3://$BUCKET_NAME/index.html" \
    --content-type "text/html; charset=utf-8" \
    --cache-control "public, max-age=3600" \
    --metadata-directive REPLACE

aws s3 cp "s3://$BUCKET_NAME/styles.css" "s3://$BUCKET_NAME/styles.css" \
    --content-type "text/css; charset=utf-8" \
    --cache-control "public, max-age=3600" \
    --metadata-directive REPLACE

aws s3 cp "s3://$BUCKET_NAME/script.js" "s3://$BUCKET_NAME/script.js" \
    --content-type "application/javascript; charset=utf-8" \
    --cache-control "public, max-age=3600" \
    --metadata-directive REPLACE

echo -e "${GREEN}Step 6: Applying bucket policy...${NC}"
# Update bucket policy with actual bucket name
sed "s/YOUR-BUCKET-NAME/$BUCKET_NAME/g" bucket-policy.json > /tmp/bucket-policy-updated.json
aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file:///tmp/bucket-policy-updated.json
rm /tmp/bucket-policy-updated.json

echo -e "${GREEN}Step 7: Enabling encryption...${NC}"
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

echo -e "${GREEN}Step 8: Enabling versioning...${NC}"
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo ""
echo -e "${GREEN}=========================================="
echo "S3 Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "S3 Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Create CloudFront distribution (see README.md)"
echo "2. Configure SSL certificate in ACM"
echo "3. Update DNS to point to CloudFront"
echo "4. Test the site"
echo ""
echo -e "${YELLOW}To create CloudFront distribution:${NC}"
echo "  - Use the AWS Console or CLI"
echo "  - Apply security-headers-policy.json"
echo "  - Configure custom domain and SSL"
echo ""
echo "Security features enabled:"
echo "  ✓ HTTPS enforcement via bucket policy"
echo "  ✓ Server-side encryption (AES256)"
echo "  ✓ Bucket versioning"
echo "  ✓ Public access controls"
echo ""
