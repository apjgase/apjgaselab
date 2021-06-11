curl --header "Content-Type: application/json" --request POST --data '{"ResetType": "PushPowerButton"}' https://10.108.1.1/redfish/v1/Systems/1/Actions/ComputerSystem.Reset -u administrator:B8JQWZFX --insecure
curl --header "Content-Type: application/json" --request POST --data '{"ResetType": "PushPowerButton"}' https://10.108.1.2/redfish/v1/Systems/1/Actions/ComputerSystem.Reset -u administrator:RFQWMJ5W --insecure
curl --header "Content-Type: application/json" --request POST --data '{"ResetType": "PushPowerButton"}' https://10.108.1.3/redfish/v1/Systems/1/Actions/ComputerSystem.Reset -u administrator:HC7DW6BK --insecure

#0.108.1.1 Administrator/B8JQWZFX
#10.108.1.2 Administrator/RFQWMJ5W
#10.108.1.3 Administrator/HC7DW6BK