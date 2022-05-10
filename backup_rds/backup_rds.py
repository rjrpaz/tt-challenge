import json  
import boto3  
import time  

def lambda_handler(event, context):  
    try: 
        region='us-east-1'
        db_instance = 'tt-db'
        current_date=time.strftime("%Y%m%d%H%M%S")

        rds = boto3.client('rds',region_name=region)
        snapshot_name = db_instance + current_date
        response = rds.describe_db_instances()

        snapshot_name = db_instance + '-' + current_date
        print("Backing up database " + db_instance + " into snapshot " + snapshot_name)
    
        try:
            rds.create_db_snapshot(DBInstanceIdentifier = db_instance,DBSnapshotIdentifier = snapshot_name)
        except Exception as e:
            print ('Error::%s'%e)

    except Exception as e:
    	print (e)

    print ('End')

    return {
        'statusCode': 200,
        'body': "OK"
    }

# lambda_handler(None, None)

