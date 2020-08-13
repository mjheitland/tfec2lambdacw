import json

def mylambda(event, context):
    print('Hello World!')
    print(event)
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }