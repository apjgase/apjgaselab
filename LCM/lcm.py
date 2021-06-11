import os
import http.client
import ssl
import json
from base64 import b64encode
from dotenv import load_dotenv

#load config
load_dotenv()

#params loaded:
#PC_IP_ADDRESS
#PE_IP_ADDRESS
#USERNAME
#PASSWORD

PE_IP_ADDRESS = os.environ.get("PE_IP_ADDRESS")
USERNAME = os.environ.get("USERNAME")
PASSWORD = os.environ.get("PASSWORD")

peCredentials = b64encode(bytes(USERNAME + ':' + PASSWORD))


conn = http.client.HTTPSConnection(PE_IP_ADDRESS, 9440,context = ssl._create_unverified_context())

payload = ''
headers = {
  'Authorization': 'Basic %s' %  peCredentials
}
conn.request("GET", "/PrismGateway/services/rest/v2.0/cluster", payload, headers)
res = conn.getresponse()
loadJsonResponse = json.loads(res.read())
print("Cluster name: " + loadJsonResponse["name"])


conn.request("GET", "/lcm/v1.r0.b1/resources/config", payload, headers)
res = conn.getresponse()

loadJsonResponse = json.loads(res.read())

# print "lcm_version": "2.4.1.2.24968",

print("LCM Version: " + loadJsonResponse["data"]["lcm_version"])


payload = json.dumps({
  "filter": "status==RUNNING"
})
headers = {
  'Authorization': 'Basic %s' %  peCredentials,
  'Content-Type': 'application/json'
}
conn.request("POST", "/lcm/v1.r0.b1/resources/tasks/list", payload, headers)
res = conn.getresponse()

loadJsonResponse = json.loads(res.read())
taskCount=loadJsonResponse["data"]["metadata"]["total_matches"]
if loadJsonResponse["data"]["metadata"]["total_matches"] == 0:
    print("No active tasks found")
else:
   
    for task in loadJsonResponse["data"]["entities"]:
        if ("percentage_complete" in task):
            print("Task type: " + task["operation_type"] + " Percentage completed: " + str(task["percentage_complete"]))
        else:
            print("Task type: " + task["operation_type"])
