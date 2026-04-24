---
description: "AWS CloudFormation setup for Amazon Connect: infrastructure as code, deployment commands, and project conventions"
---

# Amazon Connect CloudFormation Setup

This project uses AWS CloudFormation to provision Amazon Connect instances and related resources.

## Key Practices

- **Templates**: Use YAML format in `templates/` directory. JSON versions available for compatibility.
- **Deployment**: Use AWS CLI for deployment: `aws cloudformation deploy --template-file templates/amazonconnect.yaml --stack-name <stack-name>`
- **Parameters**: Environment-specific parameters in `parameters/` directory.
- **Contact Flows**: JSON files in `contact-flows/` for Connect contact flows.
- **Lambdas**: Python functions in `lambdas/` with runtime python3.13.
- **Lex Bots**: Bot configurations in `lex-bots/`.

## Architecture

- Comprehensive template (`templates/amazonconnect.yaml`) creates Connect instance, KMS, S3, queues, profiles, users, flows, phone numbers, and Lambda functions.
- Instance alias auto-generated from CloudFormation stack ID.
- S3 bucket encrypted with KMS for call recordings.

## Common Pitfalls

- Ensure Amazon Connect is enabled in your AWS region.
- Required IAM permissions: CloudFormation, Connect, S3, Lambda, IAM, KMS, Secrets Manager.
- Phone numbers may require additional verification in some regions.
- Lambda functions may need VPC configuration for Connect integration.

## Links

- [Project README](README.md) for detailed setup and prerequisites.
- [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/) for template syntax.
- [Amazon Connect Admin Guide](https://docs.aws.amazon.com/connect/latest/adminguide/) for service specifics.</content>
<parameter name="filePath">/Users/sateesh/D-Drive/MyProjects/aws-poc/cft/connect-setup-cft/AGENTS.md