import os
import psycopg2
import psycopg2.extras

import base64



def lambda_handler(event, context):
    try:
        dsn="dbname='{}' user={} password={} port='{}' host='{}'".format(
            os.environ['REDSHIFT_DATABASE'],
            os.environ['REDSHIFT_USER'],
            os.environ['REDSHIFT_PASSWD'],
            os.environ['REDSHIFT_PORT'],
            os.environ['REDSHIFT_ENDPOINT']
            )
        # print(dsn)
        # connection=psycopg2.connect(dsn)
        # cursor = connection.cursor()
        # # Print PostgreSQL Connection properties
        # sql = 'CREATE TABLE IF NOT EXISTS tracking.one ( request_id CHAR(36) NOT NULL);'
        # cursor.execute(sql)
        # connection.commit()

        # print ( connection.get_dsn_parameters(),"\n")

    except (Exception, psycopg2.Error) as error :
        print ("Error while connecting to PostgreSQL", error)

    finally:
        #closing database connection.
        if(connection):
            cursor.close()
            connection.close()
            print("PostgreSQL connection is closed")
    #for record in event['Records']:
       #Kinesis data is base64 encoded so decode here
    #   payload=base64.b64decode(record["kinesis"]["data"])
    #   print("Decoded payload: " + str(payload))
