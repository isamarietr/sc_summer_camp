#!/bin/bash

# Install sshpass
# Make sure VMs have openssh-server installed

# Variables
BASE_VM_NAME="base_ubuntu"
PASSWORD=`cat ./password.txt`

APP_MACHINES=("host01" "host02" "host03")

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

ip1=$(VBoxManage guestproperty get host01 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip2=$(VBoxManage guestproperty get host02 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip3=$(VBoxManage guestproperty get host03 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

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
