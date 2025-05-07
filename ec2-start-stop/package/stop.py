import json
import boto3
import time


def lambda_handler(event, context):
    client = boto3.client('ec2')
    print("Event received:", event)

    stopTime = event['stop-time']
    print("Stop time from event:", stopTime)

    # Define filter for running instances with matching stop-time tag
    custom_filter = [
        {
            'Name': 'instance-state-name',
            'Values': ['running']
        },
        {
            'Name': 'tag:stop-time',
            'Values': [stopTime]
        }
    ]

    print("Using filter:", custom_filter)

    response = client.describe_instances(Filters=custom_filter, MaxResults=1000)

    instance_ids = []
    for resrv in response['Reservations']:
        for instance in resrv['Instances']:
            instance_ids.append(instance['InstanceId'])
            print("Instance to stop:", instance['InstanceId'])

    if instance_ids:
        client.stop_instances(InstanceIds=instance_ids)
        print("Stopping instances:", instance_ids)
    else:
        print("No matching instances to stop.")


