# Amazon Connect CloudFormation Setup

This project contains modularized CloudFormation templates to deploy Amazon Connect with Kinesis streaming and Lambda event processors.

## New Modular Architecture

The infrastructure is now organized into **nested stacks** with **externalized code**:

```
connect-setup-cft/
├── templates/
│   ├── main.yaml                    # Parent stack (coordinates deployment)
│   ├── stacks/
│   │   ├── iam-role.yaml           # IAM roles and policies
│   │   ├── storage.yaml            # S3 and KMS encryption
│   │   ├── kinesis-streams.yaml    # Kinesis streams for CTR and Agent Events
│   │   ├── lambdas.yaml            # Lambda functions
│   │   └── connect-instance.yaml   # Connect instance and related resources
│   ├── amazonconnect.yaml          # Legacy monolithic template (deprecated)
│   └── template.yaml/template.json # Basic vanilla templates
│
├── lambdas/
│   ├── ctr-processor/
│   │   └── lambda_function.py      # CTR processing logic
│   └── agent-event-processor/
│       └── lambda_function.py      # Agent event processing logic
│
├── contact-flows/
│   └── welcome.json                # Sample contact flow
│
├── scripts/
│   ├── deploy.sh                   # Automated deployment script
│   └── .gitinclude
│
├── parameters/
├── lex-bots/
├── docs/
└── README.md
```

## Benefits of Modular Architecture

✅ **Separation of Concerns**: Each stack handles one responsibility
✅ **Reusability**: Stacks can be deployed independently 
✅ **Maintainability**: Easier to update individual components
✅ **Version Control**: Lambda code tracked in git, not embedded in YAML
✅ **Testing**: Test individual stacks in isolation
✅ **Scaling**: Independently adjust resources like Kinesis shards

## Template Overview

| Stack | Purpose | Resources |
|-------|---------|-----------|
| `main.yaml` | Orchestrates nested stacks | Deployment coordination |
| `iam-role.yaml` | IAM permissions | Lambda execution role, policies |
| `storage.yaml` | S3 and encryption | S3 bucket, KMS key |
| `kinesis-streams.yaml` | Event streaming | CTR stream, Agent Event stream |
| `lambdas.yaml` | Event processors | Lambda functions, Log groups, Event source mappings |
| `connect-instance.yaml` | Core Connect infrastructure | Instance, queues, routing profiles, users, flows, storage config |

## Prerequisites

- AWS CLI v2 installed and configured
- IAM permissions for:
  - CloudFormation (stack management)
  - Amazon Connect (full access)
  - S3 (bucket creation, object uploads)
  - Lambda (function creation, role management)
  - IAM (role creation)
  - KMS (key creation)
  - Kinesis (stream creation)
  - CloudWatch Logs (log group creation)
  - Secrets Manager (secret creation)
- AWS account with Amazon Connect service **enabled in your region**

## Quick Start

### Step 1: Make deployment script executable
```bash
chmod +x scripts/deploy.sh

aws cloudformation deploy \
  --template-file templates/amazonconnect.yaml \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
  --no-execute-changeset
```

Then review and execute manually:
```bash
# List changesets
aws cloudformation list-change-sets \
  --stack-name my-connect-stack \
  --region us-east-1

# Describe changeset details
aws cloudformation describe-change-set \
  --change-set-name <changeset-name> \
  --stack-name my-connect-stack \
  --region us-east-1

# Execute the changeset
aws cloudformation execute-change-set \
  --change-set-name <changeset-name> \
  --stack-name my-connect-stack \
  --region us-east-1
```

### Method 3: Create/Update Stack (Lower-level)

For more control, use create or update commands:

```bash
# Create stack (new)
aws cloudformation create-stack \
  --template-body file://templates/amazonconnect.yaml \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

# Update existing stack
aws cloudformation update-stack \
  --template-body file://templates/amazonconnect.yaml \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
```

## Deployment Instructions

### Automated Deployment (Recommended)

The easiest way to deploy is using the provided deployment script, which:
1. Packages Lambda functions into zip files
2. Uploads them to S3
3. Uploads CloudFormation templates to S3
4. Deploys the parent stack with all nested stacks

```bash
# Make script executable (first time only)
chmod +x scripts/deploy.sh

# Deploy with default auto-generated S3 bucket
./scripts/deploy.sh my-connect-stack us-east-1

# Or specify your own S3 bucket for Lambda code
./scripts/deploy.sh my-connect-stack us-east-1 my-existing-bucket
```

The script will:
- Create the S3 bucket if needed
- Package and upload Lambda functions
- Upload all nested stack templates
- Deploy the CloudFormation stack
- Display all outputs including Connect login URL

### Manual Deployment

If you prefer more control, follow these steps:

#### Step 1: Prepare S3 bucket
```bash
# Create an S3 bucket for Lambda packages
BUCKET_NAME="connect-lambda-code-$(date +%s)"
aws s3 mb s3://$BUCKET_NAME --region us-east-1
```

#### Step 2: Package Lambda functions
```bash
# CTR Processor
cd lambdas/ctr-processor
zip -r ../../ctr-processor.zip .
aws s3 cp ../../ctr-processor.zip s3://$BUCKET_NAME/lambda/ctr-processor.zip --region us-east-1
cd ../..

# Agent Event Processor
cd lambdas/agent-event-processor
zip -r ../../agent-event-processor.zip .
aws s3 cp ../../agent-event-processor.zip s3://$BUCKET_NAME/lambda/agent-event-processor.zip --region us-east-1
cd ../..
```

#### Step 3: Upload CloudFormation templates
```bash
# Upload nested templates
aws s3 cp templates/stacks/iam-role.yaml s3://$BUCKET_NAME/templates/stacks/iam-role.yaml --region us-east-1
aws s3 cp templates/stacks/storage.yaml s3://$BUCKET_NAME/templates/stacks/storage.yaml --region us-east-1
aws s3 cp templates/stacks/kinesis-streams.yaml s3://$BUCKET_NAME/templates/stacks/kinesis-streams.yaml --region us-east-1
aws s3 cp templates/stacks/lambdas.yaml s3://$BUCKET_NAME/templates/stacks/lambdas.yaml --region us-east-1
aws s3 cp templates/stacks/connect-instance.yaml s3://$BUCKET_NAME/templates/stacks/connect-instance.yaml --region us-east-1
```

#### Step 4: Deploy the stack
```bash
aws cloudformation deploy \
  --template-file templates/main.yaml \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --parameter-overrides LambdaCodeBucket=$BUCKET_NAME \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM
```

## After Deployment

### Get Connect Login URL
```bash
aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`CCPLoginUrl`].OutputValue' \
  --output text
```

### Get Admin Credentials
```bash
# Get the Secrets Manager secret name
SECRET_NAME=$(aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`AdminPasswordSecret`].OutputValue' \
  --output text)

# Retrieve the password
aws secretsmanager get-secret-value \
  --secret-id $SECRET_NAME \
  --region us-east-1 \
  --query 'SecretString' | jq '.password'
```

### Monitor Lambda Processing

View logs for CTR processing:
```bash
# Stream logs for CTR processor
aws logs tail /aws/lambda/connect-ctr-processor-my-connect-stack --region us-east-1 --follow
```

View logs for Agent Event processing:
```bash
# Stream logs for Agent Event processor
aws logs tail /aws/lambda/connect-agent-event-processor-my-connect-stack --region us-east-1 --follow
```

## Troubleshooting

### Stack Creation Failed
```bash
# View stack events
aws cloudformation describe-stack-events \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`DELETE_FAILED`]' \
  --output table
```

### Lambda Function Errors
```bash
# Check Lambda execution logs
aws logs describe-log-groups \
  --log-group-name-prefix /aws/lambda/connect \
  --region us-east-1

# Get recent errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/connect-ctr-processor-my-connect-stack \
  --region us-east-1 \
  --filter-pattern "ERROR"
```

### Kinesis Stream Not Receiving Data
1. Verify Connect instance storage config is configured:
   ```bash
   # Check stack outputs
   aws cloudformation describe-stacks \
     --stack-name my-connect-stack \
     --region us-east-1 \
     --query 'Stacks[0].Outputs'
   ```

2. Ensure Lambda event source mapping is active:
   ```bash
   aws lambda list-event-source-mappings \
     --function-name connect-ctr-processor-my-connect-stack \
     --region us-east-1
   ```

## Cleanup

To delete all resources and avoid ongoing charges:

```bash
# Delete the CloudFormation stack (cascades to nested stacks)
aws cloudformation delete-stack \
  --stack-name my-connect-stack \
  --region us-east-1

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
  --stack-name my-connect-stack \
  --region us-east-1

# Clean up S3 bucket and objects
aws s3 rm s3://$BUCKET_NAME --recursive --region us-east-1
aws s3 rb s3://$BUCKET_NAME --region us-east-1
```

## Lambda Code Structure

Each Lambda function is organized as:
```
lambdas/
  ctr-processor/
    lambda_function.py  # Handler function
  agent-event-processor/
    lambda_function.py  # Handler function
```

**To modify Lambda code:**
1. Update the Python file in `lambdas/*/`
2. Re-run the deployment script (or manually zip and upload)
3. The new version will be deployed

## Extending the Setup

### Add a New Lambda Processor
1. Create a new directory: `lambdas/your-processor/`
2. Add `lambda_function.py` with your handler
3. Update `deploy.sh` to package and upload it
4. Create parameters in `templates/stacks/lambdas.yaml`
5. Update `main.yaml` to pass the code bucket reference

### Modify Contact Flow
1. Edit the JSON in `templates/stacks/connect-instance.yaml` under the `ContactFlow` resource
2. Or externalize to a separate JSON file and reference it
3. Re-deploy the stack

### Scale Kinesis Streams
Edit `templates/stacks/kinesis-streams.yaml` and change `ShardCount` values to scale throughput.

## Common Issues & Solutions

### Issue: Amazon Connect not enabled in region
**Solution:** Ensure the region supports Amazon Connect. Valid regions include us-east-1, us-west-2, eu-west-1, ap-southeast-1, etc.

### Issue: Lambda cannot read from Kinesis stream
**Solution:** Verify the IAM role in `iam-role.yaml` has `kinesis:GetRecords` and related permissions.

### Issue: Events not appearing in CloudWatch Logs
**Solution:** Check that the event source mapping is active and the Lambda function has proper IAM permissions for CloudWatch Logs.

## Support & Documentation

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [Amazon Connect Admin Guide](https://docs.aws.amazon.com/connect/latest/adminguide/)
- [Amazon Connect API Reference](https://docs.aws.amazon.com/connect/latest/APIReference/)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/)
- [Amazon Kinesis Data Streams](https://docs.aws.amazon.com/kinesis/latest/dev/)

  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`KmsKeyId`].OutputValue' \
  --output text

aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`UserName`].OutputValue' \
  --output text

aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`SecretName`].OutputValue' \
  --output text
```

### Available Outputs

The template provides the following outputs:

- **ConnectInstanceUrl**: Amazon Connect login URL
- **ConnectInstanceArn**: Amazon Connect instance ARN
- **ConnectInstanceId**: Amazon Connect instance ID  
- **ConnectInstanceAlias**: Amazon Connect instance alias
- **S3BucketName**: S3 bucket name for call recordings
- **S3BucketArn**: S3 bucket ARN for call recordings
- **KmsKeyId**: KMS key ID for S3 encryption
- **KmsKeyArn**: KMS key ARN for S3 encryption
- **HoursOfOperationArn**: Hours of operation ARN
- **QueueArn**: Connect queue ARN
- **RoutingProfileArn**: Routing profile ARN
- **UserArn**: Connect user ARN
- **UserName**: Connect username (Sampleadmin)
- **ContactFlowArn**: Contact flow ARN
- **IamRoleArn**: IAM role ARN for Lambda functions
- **LambdaFunctionArn**: Lambda function ARN
- **SecretArn**: Secrets Manager secret ARN for user password
- **SecretName**: Secrets Manager secret name for user password

## Stack Management

### List All Stacks

```bash
# List active stacks
aws cloudformation list-stacks \
  --region us-east-1 \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# List all stacks (including deleted)
aws cloudformation list-stacks \
  --region us-east-1 \
  --query 'StackSummaries[].{Name:StackName,Status:StackStatus,Created:CreationTime}'
```

### Delete Stack

```bash
# Delete the stack
aws cloudformation delete-stack \
  --stack-name my-connect-stack \
  --region us-east-1

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
  --stack-name my-connect-stack \
  --region us-east-1
```

### Validate Template

```bash
# Validate before deployment
aws cloudformation validate-template \
  --template-body file://templates/amazonconnect.yaml

# Validate with S3 URL
aws cloudformation validate-template \
  --template-url https://s3.amazonaws.com/bucket/template.yaml
```

## Accessing the Connect Instance

After successful deployment:

1. **Web Access:**
   - Get the URL from outputs: `ConnectInstanceUrl`
   - Open in browser and sign in with:
     - **Username:** `Sampleadmin` (from outputs)
     - **Password:** Retrieve from AWS Secrets Manager console

2. **AWS Management Console:**
   - Go to Amazon Connect console
   - Select your instance from the list
   - Configure additional users, phone numbers, and contact flows

3. **Retrieve Password:**
   ```bash
   # Get the secret name
   aws secretsmanager list-secrets \
     --region us-east-1 \
     --query 'SecretList[?Name==`AgentPassword-my-connect-stack`].ARN'
   
   # Get the password
   aws secretsmanager get-secret-value \
     --secret-id AgentPassword-my-connect-stack \
     --region us-east-1 \
     --query 'SecretString' | jq '.password'
   ```

## Cleanup and Rollback

### Delete Everything

```bash
# Delete stack (removes all resources)
aws cloudformation delete-stack \
  --stack-name my-connect-stack \
  --region us-east-1

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name my-connect-stack \
  --region us-east-1

# Verify deletion
aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1
```

### Handle Stuck Stacks

If a stack is in `ROLLBACK_COMPLETE` or `DELETE_FAILED`:

```bash
# Force delete (if normal delete fails)
aws cloudformation delete-stack \
  --stack-name my-connect-stack \
  --region us-east-1

# Check stack status
aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus'
```

**Warning:** Deleting the stack will permanently remove the Amazon Connect instance and all associated resources (S3 recordings, users, contact flows, etc.). Make sure to back up important data first.

## Troubleshooting

### S3 Bucket Name Already Exists
**Error:** `The requested bucket name is not available`

**Cause:** S3 bucket names must be globally unique. The template includes account ID and stack ID to ensure uniqueness, but if you reuse the same stack name, it may conflict.

**Solution:**
1. Use a different stack name
2. Delete the old stack and wait for full deletion
3. Deploy with a new stack name

### Stack in ROLLBACK_COMPLETE State
**Error:** `Stack is in ROLLBACK_COMPLETE state and cannot be updated`

**Solution:**
```bash
# Delete the failed stack
aws cloudformation delete-stack --stack-name my-connect-stack --region us-east-1

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name my-connect-stack --region us-east-1

# Redeploy
aws cloudformation deploy --template-file templates/amazonconnect.yaml --stack-name my-connect-stack --region us-east-1 --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
```

### Lambda Custom Resources Timeout
**Error:** Lambda functions fail during stack creation

**Cause:** The template uses Lambda custom resources to configure Connect resources, which may take 5-10 minutes.

**Solution:**
- Be patient during initial deployment
- Check CloudWatch logs for Lambda function errors
- Verify IAM role has correct permissions

### Region Not Supported
**Error:** Early validation error for Connect instance

**Cause:** Amazon Connect may not be available in your region

**Solution:**
- Check [AWS documentation](https://docs.aws.amazon.com/connect/latest/adminguide/regions.html) for supported regions
- Use a supported region (us-east-1, us-west-2, eu-west-1, etc.)

### Permission Denied Errors
**Cause:** IAM user/role lacks necessary permissions

**Solution:** Ensure your IAM user has permissions for:
- `cloudformation:*`
- `connect:*`
- `s3:*`
- `lambda:*`
- `iam:*`
- `kms:*`
- `secretsmanager:*`

### Phone Number Stabilization Issues
**Current Status:** Phone number resources are commented out for testing. The stack deploys successfully without them.

**To Enable Phone Numbers:**
1. Uncomment the phone number related sections in `templates/amazonconnect.yaml`:
   - `SamplePhonenumber` resource
   - `SamplePhoneNumberWaiter` custom resource  
   - `SampleAssignClaimedPhoneNumber` custom resource
   - `SampleFnAssignClaimedPhoneNumber` Lambda function
   - `SamplePhoneNumberWaiterFunction` Lambda function
   - `TollFreeNumber` output
2. Add back `connect:DescribePhoneNumber` permission to the IAM policy
3. Redeploy the stack

If you encounter "Resource did not stabilize" errors for phone numbers:
- The commented code includes automatic retry logic (up to 10 attempts with 30-second delays)
- Monitor the CloudFormation stack events to see the waiter progress
- If issues persist, try deploying in a different region or contact AWS support

## Best Practices

1. **Use changeset review** for production deployments (`--no-execute-changeset`)
2. **Test in non-production** environment first
3. **Back up important data** before deleting stacks
4. **Use meaningful stack names** for easier identification
5. **Monitor stack events** during deployment
6. **Set up CloudWatch alarms** for production stacks
7. **Document any manual changes** made outside of CloudFormation
8. **Regularly validate templates** for syntax errors

## Additional Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [Amazon Connect Documentation](https://docs.aws.amazon.com/connect/)
- [AWS CLI CloudFormation Reference](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/)