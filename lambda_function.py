import os
import psycopg2
import psycopg2.extras

import base64



def lambda_handler(event, context):
    db = psycopg2.connect(
        dbname=os.environ['REDSHIFT_DATABASE'],
        user=os.environ['REDSHIFT_USER'],
        password=os.environ['REDSHIFT_PASSWD'],
        port=os.environ['REDSHIFT_PORT'],
        host=os.environ['REDSHIFT_ENDPOINT']
        )

    for record in event['Records']:
       #Kinesis data is base64 encoded so decode here
       payload=base64.b64decode(record["kinesis"]["data"])
       print("Decoded payload: " + str(payload))
