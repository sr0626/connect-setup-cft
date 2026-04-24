"""
Lambda function to process Contact Trace Records from Kinesis and log to CloudWatch.
"""
import json
import base64
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """Process Kinesis records containing CTR data."""
    for record in event['Records']:
        try:
            # Decode the base64 encoded data
            payload = base64.b64decode(record['kinesis']['data'])
            data = json.loads(payload.decode('utf-8'))
            
            # Log the CTR event as JSON
            logger.info(json.dumps(data))
            
        except Exception as e:
            logger.error(f"Error processing record: {str(e)}")
            logger.error(f"Raw data: {record['kinesis']['data']}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }
