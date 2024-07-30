#!/bin/bash

# Install sshpass
# Make sure VMs have openssh-server installed

# Variables
BASE_VM_NAME="base_ubuntu"
PASSWORD=`cat ./password.txt`

APP_MACHINES=("host1" "host2" "host3")

## TODO: Create project, get Project Id and Api key
## TODO: Get OM URL from previous script
# ./setup_agents.sh http://192.168.1.252 66a9464faf44f518147f13d9 66a94670af44f518147f143eb5ef7a106704f1606167da9cd869d15b
LB=$1
PROJECT_ID=$2
API_KEY=$3

echo "===== Apss Machines..."
for NEW_VM in "${APP_MACHINES[@]}"
do
VBoxManage clonevm "$BASE_VM_NAME" --name "$NEW_VM" --register
VBoxManage startvm "$NEW_VM" --type headless
done
echo "Waiting for the VMs to boot..."
sleep 45

ip1=$(VBoxManage guestproperty get host1 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip2=$(VBoxManage guestproperty get host2 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip3=$(VBoxManage guestproperty get host3 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

for MDB_VM in "${APP_MACHINES[@]}"
do

# Get the IP
mdb_ip=$(VBoxManage guestproperty get $MDB_VM "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

LB_URL="$LB" 

echo "Setting up hostnames..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$mdb_ip << EOF
    sudo hostnamectl set-hostname $MDB_VM
    sudo shutdown -r now
EOF
done

echo "Waiting for hosts to come back with a new hostname..."
sleep 30

ip1=$(VBoxManage guestproperty get host1 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip2=$(VBoxManage guestproperty get host2 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip3=$(VBoxManage guestproperty get host3 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

for MDB_VM in "${APP_MACHINES[@]}"
do

# Get the IP
mdb_ip=$(VBoxManage guestproperty get $MDB_VM "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

LB_URL="$LB" 

echo "Installing Agents..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$mdb_ip << EOF
    sudo apt-get install -y gnupg curl

    curl -OL https://cloud.mongodb.com/download/agent/automation/mongodb-mms-automation-agent-manager_latest_amd64.ubuntu1604.deb

    sudo dpkg -i mongodb-mms-automation-agent-manager_latest_amd64.ubuntu1604.deb

    echo "mmsGroupId=$PROJECT_ID" >> ~/automation-agent.config
    echo "mmsApiKey=$API_KEY" >> ~/automation-agent.config
    echo "mmsBaseUrl=$LB_URL" >> ~/automation-agent.config
    echo "httpProxy=$LB_URL" >> ~/automation-agent.config
    echo "logFile=/var/log/mongodb-mms-automation/automation-agent.log" >> ~/automation-agent.config
    echo "mmsConfigBackup=/var/lib/mongodb-mms-automation/mms-cluster-config-backup.json" >> ~/automation-agent.config
    echo "logLevel=INFO" >> ~/automation-agent.config
    echo "maxLogFiles=10" >> ~/automation-agent.config
    echo "maxLogFileSize=268435456" >> ~/automation-agent.config

    sudo mv ~/automation-agent.config /etc/mongodb-mms/automation-agent.config
    sudo mkdir -p /data; sudo chown mongodb:mongodb /data
    sudo systemctl start mongodb-mms-automation-agent

    # setup firewall
    sudo ufw allow 27017
    sudo ufw allow 8080
    sudo ufw allow 22

    sudo systemctl start mongodb-mms-automation-agent.service
    sudo systemctl enable mongodb-mms-automation-agent.service
EOF
sleep 1
done

ip1=$(VBoxManage guestproperty get host1 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip2=$(VBoxManage guestproperty get host2 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip3=$(VBoxManage guestproperty get host3 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')


echo "Done!"
echo "host1"
echo $ip1
echo "host2"
echo $ip2
echo "host3"
echo $ip3
