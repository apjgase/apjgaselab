#!/usr/local/bin/python3

import boto3
import warnings
warnings.filterwarnings("ignore")

endpoint_ip= "10.139.80.53" #Replace this value
access_key_id="FU09yv3CRHdr4jCaemd0L3A8Y4UkESKw" #Replace this value
secret_access_key="SOStNqINLEsQgRy8xrhHp7CU3FjnAjM8" #Replace this value
endpoint_url= "https://"+endpoint_ip+":443"


session = boto3.session.Session()
s3client = session.client(service_name="s3", aws_access_key_id=access_key_id, aws_secret_access_key=secret_access_key, endpoint_url=endpoint_url, verify=False)

# list the buckets
response = s3client.list_buckets()

for b in response['Buckets']:
  print (b['Name'])