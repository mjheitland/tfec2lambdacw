# client.create_event_source_mapping() works only if this 
# code is not run in a private VPC (either on ec2 or lambda).
# Might work in a private VPC if private lambda endpoints are available.
import json
import boto3

def mylambda(event, context):
    print('Hello World from register_sqs!')
    print(event)
    register_sqs()

def register_sqs():    
    print('checkpoint 0')
    client = boto3.client("sts") # account_id = client.get_caller_identity()#["Account"]
    caller = client.get_caller_identity()
    print(caller)
    print('checkpoint 1')
    client = boto3.client('lambda', 'eu-west-1')
    print('checkpoint 2')
    response = client.create_event_source_mapping(
        EventSourceArn = 'arn:aws:sqs:eu-west-1:094033154904:mysqs',
        FunctionName = 'arn:aws:lambda:eu-west-1:094033154904:function:mylambda',
        Enabled = True,
        BatchSize = 1)
    print('checkpoint 3')
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
    
if __name__ == '__main__':
    register_sqs()