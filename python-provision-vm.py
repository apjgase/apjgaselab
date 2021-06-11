import http.client
import argparse
import http.client
import argparse
import json

#connection configuration 
prism_central_ip="10.139.80.41:9440"

#ignore SSL
import os, ssl
if (not os.environ.get('PYTHONHTTPSVERIFY', '') and
    getattr(ssl, '_create_unverified_context', None)):
    ssl._create_default_https_context = ssl._create_unverified_context

#parse variables to get VM name
# Instantiate the parser
parser = argparse.ArgumentParser(description='VM provisioning on Nutanix AHV simple demo script')
# Required  argument
parser.add_argument('Virtual machine name',
                    help='A required vm name argument')
args = parser.parse_args()

vm_name=args.vm_name

payload = {
	"metadata": {
		"kind": "vm"
	},
	"spec": {
		"name": vm_name,
		"resources": {
			"disk_list": [
				{
					"data_source_reference": {
						"kind": "image",
						"uuid": "d0a0363f-449b-4bde-913c-142016a8eb4a"
					},
					"device_properties": {
						"device_type": "DISK",
						"disk_address": {
							"adapter_type": "SCSI",
							"device_index": 0
						}
					}
				}
				],
			"nic_list": [
				{
					"subnet_reference": {
					"kind": "subnet",
					"uuid": "7303b7bd-1d31-42b0-b76f-548e493a2760"
				    	          }  
				        	    }
				        	  ],
			"memory_size_mib": 4048,
			"num_sockets": 2,
			"num_vcpus_per_socket": 1,
			"power_state": "ON"
		}
	}
}

payload_json = json.dumps(payload)  # Convert dict to json string
conn = http.client.HTTPSConnection(prism_central_ip)
headers = {
	'content-type': "application/json",
   	'authorization': "Basic YWRtaW46TnV0YW5peEAxMjM="
   	}

conn.request("POST", "/api/nutanix/v3/vms", payload_json, headers)

res = conn.getresponse()
data = res.read()

print(data.decode("utf-8"))                                      