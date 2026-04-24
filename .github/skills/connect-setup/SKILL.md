---
name: connect-setup
description: "AWS CloudFormation setup for Amazon Connect: modular infrastructure as code, deployment automation, and project conventions"
---

# Amazon Connect CloudFormation Setup

This project uses modularized AWS CloudFormation to provision Amazon Connect instances with Kinesis event streaming and Lambda processors.

## Architecture

**Nested Stack Design:**
- `main.yaml` (parent) orchestrates 5 child stacks
- `iam-role.yaml` - IAM permissions for Lambda functions
- `storage.yaml` - S3 bucket and KMS encryption for call recordings
- `kinesis-streams.yaml` - Kinesis streams for Contact Trace Records (CTR) and Agent Events
- `lambdas.yaml` - Lambda event processors that log to CloudWatch
- `connect-instance.yaml` - Amazon Connect instance, queues, routing profiles, users, contact flows, and storage configuration

**Benefits:**
- Separation of concerns by resource type
- Reusable, independently deployable stacks
- Version-controlled Lambda code (not embedded in YAML)
- Automated deployment via bash script
- Scales easily (adjust Kinesis shards, Lambda memory, etc.)

## Deployment

**Quick start with automation:**
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh my-connect-stack us-east-1
```

The script automatically:
- Packages Lambda functions into zip files
- Uploads to S3
- Deploys all nested stacks
- Outputs Connect login URL and credentials

**Manual deployment:**
1. Package Lambda code: `lambdas/ctr-processor/` and `lambdas/agent-event-processor/`
2. Upload templates and code to S3
3. Deploy `templates/main.yaml` with `LambdaCodeBucket` parameter

## Code Organization

**Lambda Functions:**
- `lambdas/ctr-processor/lambda_function.py` - Processes Contact Trace Records
- `lambdas/agent-event-processor/lambda_function.py` - Processes Agent Events
- Both decode Kinesis base64 data and log JSON to CloudWatch Logs

**Contact Flows:**
- Currently embedded in `templates/stacks/connect-instance.yaml`
- Can be externalized to `contact-flows/*.json` and referenced via file upload

## Key Practices

- **Templates**: YAML in `templates/stacks/` directory, organized by entity type
- **Lambda Code**: Python files in `lambdas/`, packaged separately from templates
- **Deployment**: Use `scripts/deploy.sh` for automated end-to-end deployment
- **Parameters**: Environment-specific via CloudFormation parameters
- **Outputs**: Export values between stacks using CloudFormation exports
- **Logging**: Lambda functions log JSON events to CloudWatch Logs for analysis

## Common Pitfalls

- Ensure Amazon Connect is **enabled in your AWS region**
- Required IAM permissions: CloudFormation, Connect, S3, Lambda, IAM, KMS, Kinesis, CloudWatch Logs, Secrets Manager
- Lambda code bucket must exist before deploying (script creates it automatically)
- Kinesis streams start with 1 shard; scale up for higher throughput in production
- Contact flow JSON is embedded; modify in template or externalize to separate files

## Extending the Setup

1. **Add a Lambda processor**: Create directory in `lambdas/`, implement handler, update `deploy.sh` and `lambdas.yaml`
2. **Scale Kinesis**: Modify `ShardCount` in `kinesis-streams.yaml`
3. **Externalize contact flows**: Save JSON to `contact-flows/`, reference via S3 in stack
4. **Add environment parameters**: Use CloudFormation parameters in `main.yaml` for dev/staging/prod

## Links

- [Automated deployment script](scripts/deploy.sh)
- [Nested stack architecture](templates/main.yaml)
- [Lambda function examples](lambdas/)
- [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/)
- [Amazon Connect Admin Guide](https://docs.aws.amazon.com/connect/latest/adminguide/)</content>
<parameter name="filePath">/Users/sateesh/D-Drive/MyProjects/aws-poc/cft/connect-setup-cft/.github/skills/connect-setup/SKILL.md