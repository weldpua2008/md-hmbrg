import os
import psycopg2
import psycopg2.extras

import base64

def get_redshift_credentials():
    role_creds = get_role_credentials()
    client = boto3.client(
        'redshift',
        region_name=CLUSTER_REGION,
        aws_access_key_id=role_creds['AccessKeyId'],
        aws_secret_access_key=role_creds['SecretAccessKey'],
        aws_session_token=role_creds['SessionToken'],
    )


def lambda_handler(event, context):
    for record in event['Records']:
       #Kinesis data is base64 encoded so decode here
       payload=base64.b64decode(record["kinesis"]["data"])
       print("Decoded payload: " + str(payload))
