# Amazon Connect CloudFormation Templates

This project contains CloudFormation templates to create Amazon Connect instances and associated resources.

## Project Structure

```
connect-setup-cft/
├── templates/
│   ├── amazonconnect.yaml       # Comprehensive template with all Connect resources
│   ├── template.yaml            # Basic vanilla Connect instance template
│   └── template.json            # JSON version of basic template
├── contact-flows/               # Amazon Connect contact flow JSON files
│   └── welcome.json            # Sample welcome contact flow
├── lambdas/
│   └── sample-function/         # Lambda function examples
├── lex-bots/                    # Amazon Lex bot configurations
├── scripts/                     # Deployment and utility scripts
├── parameters/                  # Parameter files for different environments
├── docs/                        # Additional documentation
└── README.md                    # This file
```

## Prerequisites

- AWS CLI installed and configured with appropriate permissions
- IAM permissions for:
  - CloudFormation (cloudformation:*)
  - Amazon Connect (connect:*)
  - S3 (s3:*)
  - Lambda (lambda:*)
  - IAM (iam:*)
  - KMS (kms:*)
  - Secrets Manager (secretsmanager:*)
- AWS account with Amazon Connect service enabled in your region

## Template Details

### Option 1: Comprehensive Template (Recommended)
**File:** `templates/amazonconnect.yaml`

Creates the following resources:
1. Amazon Connect Instance (CONNECT_MANAGED)
2. KMS Key for S3 encryption
3. S3 Bucket for call recordings
4. Hours of Operation (24x7)
5. Amazon Connect Queue
6. Amazon Connect Routing Profile
7. Amazon Connect User (Admin)
8. Amazon Connect Contact Flow (sample)
9. Amazon Connect Phone Number (Toll-Free) - COMMENTED OUT FOR TESTING
10. IAM Role for Lambda execution
11. Lambda functions for configuration - phone number functions commented out
12. Lambda function to assign phone numbers to contact flows

**Deployment time:** 10-15 minutes (includes Lambda execution)

### Option 2: Basic Vanilla Template
**File:** `templates/template.yaml` or `templates/template.json`

Creates:
- An Amazon Connect instance with CONNECT_MANAGED identity management
- Inbound and outbound calls enabled
- Instance alias: "my-connect-instance"

**Deployment time:** 5-10 minutes

## Deployment Instructions

### Method 1: Direct Deployment (Automatic Execution)

Deploy the template directly without changeset review:

```bash
# Comprehensive template
aws cloudformation deploy \
  --template-file templates/amazonconnect.yaml \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

# Note: Phone number resources are currently commented out for testing
# The stack will deploy successfully without them
```

Or for the basic template:
```bash
aws cloudformation deploy \
  --template-file templates/template.yaml \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --capabilities CAPABILITY_NAMED_IAM
```

### Method 2: Changeset with No Auto-Execution

Create changeset and review before executing:

```bash
# Create changeset without executing
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

## Monitoring Deployment

### Check Stack Status

```bash
# Get current stack status
aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus'
```

### View Stack Events

```bash
# List all events
aws cloudformation describe-stack-events \
  --stack-name my-connect-stack \
  --region us-east-1

# View only failed events
aws cloudformation describe-stack-events \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`DELETE_FAILED`]'
```

### Wait for Completion

```bash
# Wait for stack creation
aws cloudformation wait stack-create-complete \
  --stack-name my-connect-stack \
  --region us-east-1

# Wait for stack update
aws cloudformation wait stack-update-complete \
  --stack-name my-connect-stack \
  --region us-east-1

# Wait for stack deletion
aws cloudformation wait stack-delete-complete \
  --stack-name my-connect-stack \
  --region us-east-1
```

## Retrieving Outputs

After successful deployment, get the Connect instance details:

```bash
# Get all outputs
aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs'

# Get specific outputs
aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ConnectInstanceUrl`].OutputValue' \
  --output text

aws cloudformation describe-stacks \
  --stack-name my-connect-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
  --output text

aws cloudformation describe-stacks \
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