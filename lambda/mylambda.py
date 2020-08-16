import gzip
import json
import base64

def mylambda(event, context):
    print('Hello World!')
    cw_data = event['awslogs']['data']
    compressed_payload = base64.b64decode(cw_data)
    uncompressed_payload = gzip.decompress(compressed_payload)
    payload = json.loads(uncompressed_payload)
    log_events = payload['logEvents']
    for log_event in log_events:
        print(f'LogEvent: {log_event}')
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }