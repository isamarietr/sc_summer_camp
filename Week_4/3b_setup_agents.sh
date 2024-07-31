#!/bin/bash

# Install sshpass
# Make sure VMs have openssh-server installed

# Variables
BASE_VM_NAME="base_ubuntu"
PASSWORD=`cat ./password.txt`

APP_MACHINES=("host01" "host02" "host03")

## TODO: Create project, get Project Id and Api key
## TODO: Get OM URL from previous script
# ./3b_setup_agents.sh http://192.168.1.252 66a9464faf44f518147f13d9 66a99d213c73ea5a0879edcb587bed465a85ffd104bb30e169eb80a5
LB=$1
PROJECT_ID=$2
API_KEY=$3


ip1=$(VBoxManage guestproperty get host01 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip2=$(VBoxManage guestproperty get host02 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip3=$(VBoxManage guestproperty get host03 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

for MDB_VM in "${APP_MACHINES[@]}"
do

# Get the IP
mdb_ip=$(VBoxManage guestproperty get $MDB_VM "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

LB_URL="$LB" 

echo "Installing Agents..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$mdb_ip << EOF
    sudo apt-get install -y gnupg curl

    # curl -OL https://cloud.mongodb.com/download/agent/automation/mongodb-mms-automation-agent-manager_latest_amd64.ubuntu1604.deb

    # sudo dpkg -i mongodb-mms-automation-agent-manager_latest_amd64.ubuntu1604.deb

    curl -OL http://192.168.1.252/download/agent/automation/mongodb-mms-automation-agent-manager_107.0.9.8621-1_amd64.ubuntu1604.deb
    sudo dpkg -i mongodb-mms-automation-agent-manager_107.0.9.8621-1_amd64.ubuntu1604.deb

    # echo "mmsGroupId=$PROJECT_ID" >> ~/automation-agent.config
    # echo "mmsApiKey=$API_KEY" >> ~/automation-agent.config
    # echo "mmsBaseUrl=$LB_URL" >> ~/automation-agent.config
    # echo "httpProxy=$LB_URL" >> ~/automation-agent.config
    # echo "logFile=/var/log/mongodb-mms-automation/automation-agent.log" >> ~/automation-agent.config
    # echo "mmsConfigBackup=/var/lib/mongodb-mms-automation/mms-cluster-config-backup.json" >> ~/automation-agent.config
    # echo "logLevel=INFO" >> ~/automation-agent.config
    # echo "maxLogFiles=10" >> ~/automation-agent.config
    # echo "maxLogFileSize=268435456" >> ~/automation-agent.config

    # sudo mv ~/automation-agent.config /etc/mongodb-mms/automation-agent.config
    sudo mkdir -p /data; sudo chown mongodb:mongodb /data

    # setup firewall
    sudo ufw allow 27017
    sudo ufw allow 8080
    sudo ufw allow 80
    sudo ufw allow 22
    echo " y" | sudo ufw enable
    # sudo systemctl start mongodb-mms-automation-agent.service
    # sudo systemctl enable mongodb-mms-automation-agent.service
EOF
sleep 1
done

ip1=$(VBoxManage guestproperty get host01 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip2=$(VBoxManage guestproperty get host02 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip3=$(VBoxManage guestproperty get host03 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')


echo "Done!"
echo "host01"
echo $ip1
echo "host02"
echo $ip2
echo "host03"
echo $ip3
