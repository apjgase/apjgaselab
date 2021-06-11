#!/usr/bin/env python

"""Script to test the external data provider in Terraform"""

import sys
import json

def read_json():
    print (data.strip() for data in sys.stdin) 
    return {data.strip() for data in sys.stdin}

def main():
    json_data_input = json.load(sys.stdin)
    print (data)
    ip_address = json_data_input["ip_address"]
    username = json_data_input["username"]
    password = json_data_input["password"]
    project_name = json_data_input["project_name"]
    network1_uuid = json_data_input["network1_uuid"]
    network2_uuid = json_data_input["network2_uuid"]
   
if __name__ == '__main__':
    main()