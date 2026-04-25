#!/bin/bash

###############################################################################
# Amazon Connect CloudFormation Deployment Script
# 
# This script packages Lambda functions and deploys the CloudFormation stack
#
# Usage: ./deploy.sh <stack-name> <aws-region> [lambda-code-bucket] [enable-kinesis-streams]
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validate arguments
if [ $# -lt 2 ]; then
    print_error "Usage: ./deploy.sh <stack-name> <aws-region> [lambda-code-bucket] [enable-kinesis-streams]"
    echo "  stack-name: CloudFormation stack name"
    echo "  aws-region: AWS region (e.g., us-east-1)"
    echo "  lambda-code-bucket: S3 bucket for Lambda packages (optional, will create if not specified)"
    echo "  enable-kinesis-streams: true/false (optional, default: true)"
    exit 1
fi

STACK_NAME=$1
AWS_REGION=$2
LAMBDA_BUCKET=${3:-"connect-lambda-code-$(date +%s)"}
ENABLE_KINESIS_STREAMS=${4:-true}

print_status "Starting Amazon Connect deployment"
print_status "Stack Name: $STACK_NAME"
print_status "Region: $AWS_REGION"
print_status "Lambda Code Bucket: $LAMBDA_BUCKET"
print_status "Enable Kinesis Streams: $ENABLE_KINESIS_STREAMS"

# Create S3 bucket if it doesn't exist
print_status "Checking if Lambda code bucket exists..."
if ! aws s3 ls "s3://$LAMBDA_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
    print_status "Creating S3 bucket: $LAMBDA_BUCKET"
    aws s3 mb "s3://$LAMBDA_BUCKET" --region "$AWS_REGION"
else
    print_status "Bucket already exists"
fi

# Package Lambda functions
print_status "Packaging Lambda functions..."

# CTR Processor
if [ -d "lambdas/ctr-processor" ]; then
    print_status "Packaging CTR processor..."
    cd lambdas/ctr-processor
    zip -r ../../ctr-processor.zip . -x "*.pyc" "__pycache__/*"
    cd ../..
    aws s3 cp ctr-processor.zip "s3://$LAMBDA_BUCKET/lambda/ctr-processor.zip" --region "$AWS_REGION"
    rm ctr-processor.zip
    print_status "CTR processor packaged and uploaded"
else
    print_error "CTR processor directory not found at lambdas/ctr-processor"
    exit 1
fi

# Agent Event Processor
if [ -d "lambdas/agent-event-processor" ]; then
    print_status "Packaging Agent Event processor..."
    cd lambdas/agent-event-processor
    zip -r ../../agent-event-processor.zip . -x "*.pyc" "__pycache__/*"
    cd ../..
    aws s3 cp agent-event-processor.zip "s3://$LAMBDA_BUCKET/lambda/agent-event-processor.zip" --region "$AWS_REGION"
    rm agent-event-processor.zip
    print_status "Agent Event processor packaged and uploaded"
else
    print_error "Agent Event processor directory not found at lambdas/agent-event-processor"
    exit 1
fi

# Upload CloudFormation templates to S3
print_status "Uploading CloudFormation templates..."
aws s3 cp templates/stacks/iam-role.yaml "s3://$LAMBDA_BUCKET/templates/stacks/iam-role.yaml" --region "$AWS_REGION"
aws s3 cp templates/stacks/storage.yaml "s3://$LAMBDA_BUCKET/templates/stacks/storage.yaml" --region "$AWS_REGION"
aws s3 cp templates/stacks/kinesis-streams.yaml "s3://$LAMBDA_BUCKET/templates/stacks/kinesis-streams.yaml" --region "$AWS_REGION"
aws s3 cp templates/stacks/lambdas.yaml "s3://$LAMBDA_BUCKET/templates/stacks/lambdas.yaml" --region "$AWS_REGION"
aws s3 cp templates/stacks/connect-instance.yaml "s3://$LAMBDA_BUCKET/templates/stacks/connect-instance.yaml" --region "$AWS_REGION"
print_status "Templates uploaded"

# Deploy CloudFormation stack
print_status "Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file templates/main.yaml \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --parameter-overrides LambdaCodeBucket="$LAMBDA_BUCKET" EnableKinesisStreams="$ENABLE_KINESIS_STREAMS" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

print_status "Retrieving stack outputs..."
aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

print_status "${GREEN}Deployment completed successfully!${NC}"
echo ""
echo "Stack Name: $STACK_NAME"
echo "Region: $AWS_REGION"
echo ""
echo "To view stack status:"
echo "  aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION"
echo ""
echo "To delete stack:"
echo "aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $AWS_REGION && aws cloudformation delete-stack --stack-name $STACK_NAME --region $AWS_REGION"


