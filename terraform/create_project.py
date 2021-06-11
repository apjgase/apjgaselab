#!/usr/bin/env python3
#
# PC RestAPI v3
# Creates a new project with 2 networks, 1 user, and no limits on VMs/CPU/etc
# RUN: scriptname <Prism IP address> <username> <password> <project_name> <network1_uuid> <network2_uuid>

import requests
import json
import sys
import warnings

class PrismAPI(object):

    def __init__(self, ip_address, username, password,project_name,network1_uuid,network2_uuid):
    # Supress warning for certificate verification from verify=False
        warnings.filterwarnings("ignore")
        self.ip_address = ip_address
        self.username = username
        self.password = password
        self.project_name = project_name
        self.network1_uuid = network1_uuid
        self.network2_uuid = network2_uuid
        base_url = 'https://%s:9440/api/nutanix/v3' % self.ip_address
        self.base_url = base_url
        s = requests.Session()
        s.auth = (self.username, self.password)
        self.s = s
 
    def create_project(self):
        url = self.base_url + '/projects'
        #JSON configuration for the new project
        #needs to be passed via json.dump() to set correct quotes
        #user UUID pre-defined
        post_data = {
            'api_version': '3.1.0',
            'metadata': {
                'kind': 'project',
                'name': 'string'
            },
            'spec': {
                'name': self.project_name,
                'description': 'VPC project',   
                'resources': {
                    'resource_domain': {
                        'resources': [
                        {
                        'limit': 0,
                        'resource_type': 'VMS'
                        }
                        ]
                    },
                    'subnet_reference_list': [
                        {
                            'kind': 'subnet',
                            'uuid': self.network1_uuid
                        },
                        {
                            'kind': 'subnet',
                            'uuid': self.network2_uuid
                        }
                    ],
                    'external_user_group_reference_list': [],
                    'user_reference_list': [
                        {
                            'kind': 'user',
                            'uuid': '8d41e42d-624e-56ee-9dc9-7e48216b6b1b',
                            'name': 'administrator@apjga.local'
                        }
                    ]
                }
            }
        }
        #print ("creating project")
        #let's send json config to prism and check the response
        create_project_task = self.s.post(url, json=post_data, verify=False)
        if create_project_task.status_code == 202 :
            #print (create_project_task.status_code)
            #202 means success, check taks id
            response = create_project_task.json()
            #print (response["status"]['execution_context']['task_uuid'])
            #return task id
            return response["status"]['execution_context']['task_uuid']
        else:
            print ('\nHTTP error code: ')
            #something went wrong, die.
            #print (create_project_task.status_code)
            #print (create_project_task.text)
            quit ()

    def check_task(self, task_uuid):
        #print ("checking task status")
        url = self.base_url + "/tasks/" + task_uuid

        while True:
            #GET task status
            poll_task = self.s.get(url, verify=False)
            #print (poll_task.status_code)
            resp = poll_task.json()
            #check if it's completed successfuly. Case-sensetive.
            if resp['percentage_complete'] == 100 and resp['status'] == 'SUCCEEDED':
                #print (resp["entity_reference_list"][0]["uuid"])
                #return project UUID (dict inside list inside dict).
                return resp["entity_reference_list"][0]["uuid"]

def main():
    #let's get data from JSON STDIN input 
    json_data_input = json.load(sys.stdin)
    ip_address = json_data_input["ip_address"]
    username = json_data_input["username"]
    password = json_data_input["password"]
    project_name = json_data_input["project_name"]
    network1_uuid = json_data_input["network1_uuid"]
    network2_uuid = json_data_input["network2_uuid"]
    #create object
    cluster_connection = PrismAPI(ip_address,username,password,project_name,network1_uuid,network2_uuid)
    task = cluster_connection.create_project()
    poll = cluster_connection.check_task(task)
    #print (poll)
    json_output_data = { 'uuid' : poll }
    #send to terraform in JSON format
    sys.stdout.write(json.dumps(json_output_data))

if __name__ == '__main__':
    sys.argv[:]
    main()