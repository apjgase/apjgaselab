import paramiko
from paramiko_expect import SSHClientInteraction
import time
import requests

CLUSTER_IP = "10.108.1.20"
NODE1_IP = "10.108.1.14"
NODE2_IP = "10.108.1.15"
NODE3_IP = "10.108.1.16"
LOGIN_ACCOUNT = "nutanix"
LOGIN_PASSWORD = "nutanix/4u"

CMD_TO_RUN="uname -a"

CMD_ON_VMS="/usr/local/nutanix/bin/acli vm.on '*'"

#CMD_SHUTDOWN_VMS="for i in `/usr/local/nutanix/bin/acli vm.list power_state=on | awk '{print $1}' | grep -v NTNX` ; do /usr/local/nutanix/bin/acli vm.shutdown $i ; done"
CMD_SHUTDOWN_VMS="/usr/local/nutanix/bin/acli vm.shutdown '*'"

#/usr/local/nutanix/bin/acli vm.off '*'; sleep 10;
CMD_STOP_CLUSTER="echo 'I agree' | /usr/local/nutanix/cluster/bin/cluster stop &"

CMD_START_CLUSTER="/usr/local/nutanix/cluster/bin/cluster start"

CMD_OFF_CVM="sudo shutdown -P now"

CMD_CLUSTER_STATUS="/usr/local/nutanix/cluster/bin/cluster status"

NODE1_REDFISH_OFF="https://10.108.1.1/redfish/v1/Systems/1/Actions/ComputerSystem.Reset" 
NODE1_REDFISH_PASS="YWRtaW5pc3RyYXRvcjpCOEpRV1pGWA=="
NODE2_REDFISH_OFF="https://10.108.1.2/redfish/v1/Systems/1/Actions/ComputerSystem.Reset" 
NODE2_REDFISH_PASS="YWRtaW5pc3RyYXRvcjpSRlFXTUo1Vw=="
NODE3_REDFISH_OFF="https://10.108.1.3/redfish/v1/Systems/1/Actions/ComputerSystem.Reset" 
NODE3_REDFISH_PASS="YWRtaW5pc3RyYXRvcjpIQzdEVzZCSw=="
NODE1_REDFISH="10.108.1.1" 
NODE2_REDFISH="10.108.1.2" 
NODE3_REDFISH="10.108.1.3" 

def ssh(node,command):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(node, username=LOGIN_ACCOUNT, password=LOGIN_PASSWORD)
    stdin_raw, stdout_raw, stderr_raw = client.exec_command(command)
    exit_code = stdout_raw.channel.recv_exit_status() 
 
    for line in stdout_raw:
       print(line.strip())

    for line in stderr_raw:
      print(line.strip())

# Clean up elements
    client.close()
    del client, stdin_raw, stdout_raw, stderr_raw

def redfish(node,password):

    url = "https://" + node + "/redfish/v1/Systems/1/Actions/ComputerSystem.Reset"

    payload = "{\"ResetType\": \"PushPowerButton\"}"
    headers = {
        'Content-Type': "application/json",
        'Authorization': "Basic "+password+"",
        'Accept': "*/*",
        'Cache-Control': "no-cache",
        'Connection': "keep-alive",
        'cache-control': "no-cache"
    }

    response = requests.request("POST", url, data=payload, headers=headers, verify=False)

    print(response.text)

print ("power on nodes")

redfish(NODE1_REDFISH,NODE1_REDFISH_PASS)
redfish(NODE2_REDFISH,NODE2_REDFISH_PASS)
redfish(NODE3_REDFISH,NODE3_REDFISH_PASS)

print ("Wait for 300 seconds")
#replace with proper check
time.sleep(300)

print ("start cluster")

ssh(NODE1_IP,CMD_START_CLUSTER)

print ("Wait for 180 seconds")
time.sleep(180)

print ("start UVMs")

ssh(CLUSTER_IP,CMD_ON_VMS)




