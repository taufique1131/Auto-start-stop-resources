import boto3
rds = boto3.client('rds')

def lambda_handler(event, context):

    #Start DB Instances
    dbs = rds.describe_db_instances()
    for db in dbs['DBInstances']:
        #Check if DB instance stopped. Start it if eligible.
        if (db['DBInstanceStatus'] == 'stopped'):
            try:
                GetTags=rds.list_tags_for_resource(ResourceName=db['DBInstanceArn'])['TagList']
                for tags in GetTags:
                #if tag "autostart=yes" is set for instance, start it
                    if(tags['Key'] == 'AutoStart' and tags['Value'] == 'True'):
                        result = rds.start_db_instance(DBInstanceIdentifier=db['DBInstanceIdentifier'])
                        print ("Starting instance: {0}.".format(db['DBInstanceIdentifier']))
            except Exception as e:
                print ("Cannot start instance {0}.".format(db['DBInstanceIdentifier']))
                print(e)

if __name__ == "__main__":
    lambda_handler(None, None)
