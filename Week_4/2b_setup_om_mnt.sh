#!/bin/bash

# Install sshpass
# Make sure VMs have  openssh-server installed

# Variables
BASE_VM_NAME="base_ubuntu"
PASSWORD=`cat ./password.txt`

OPS_MACHINES=("ops1" "ops2" )
LB_MACHINES=("lb")


ip1=$(VBoxManage guestproperty get ops1 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip2=$(VBoxManage guestproperty get ops2 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip3=$(VBoxManage guestproperty get lb "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

echo "Setting up shared folder..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$ip3 << EOF
     mkdir -p /home/ubuntu/shared
EOF
sleep 1

echo "Setting up shared fs - ops1..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$ip1 << EOF
    sudo apt update
    sudo apt install sshfs
    sudo mkdir -p /mnt/shared
    sudo sshfs -o allow_other,default_permissions ubuntu@$ip3:/home/ubuntu/shared /mnt/shared
EOF
sleep 1

echo "Setting up shared fs - ops2..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$ip2 << EOF
    sudo apt update
    sudo apt install sshfs
    sudo mkdir -p /mnt/shared
    sudo sshfs -o allow_other,default_permissions ubuntu@$ip3:/home/ubuntu/shared /mnt/shared
EOF
sleep 1

echo "Done!"

echo "OPS1"
echo $ip1
echo "OPS2"
echo $ip2
