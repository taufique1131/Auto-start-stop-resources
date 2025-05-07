import json
import time
import boto3

def lambda_handler(event, context):
    client = boto3.client('ec2')
    print(event)

    startTime = event['start-time']
    print(startTime)

    ### Define Filter for Describe Instance
    custom_filter = [
        {
            'Name': 'instance-state-name',
            'Values': ['stopped']
        },
        {
            'Name': 'tag:start-time',
            'Values': [startTime]
        }
    ]

    print(custom_filter)

    ### Get instance details based on filter
    response = client.describe_instances(Filters=custom_filter, MaxResults=1000)

    instCnt = 0
    instanceId = []
    for resrv in response['Reservations']:
        for instance in resrv['Instances']:
            instanceId.append(instance['InstanceId'])
            print(instanceId)

    if len(instanceId) > 0:
        # TODO: write code...
        client.start_instances(InstanceIds=instanceId)
        print('Starting your instances: ' + str(instanceId))
    else:
        print('nothing to start')

