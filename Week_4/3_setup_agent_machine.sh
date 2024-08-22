#!/bin/bash

# Install sshpass
# Make sure VMs have openssh-server installed

# Variables
BASE_VM_NAME="base_ubuntu"
PASSWORD=`cat ./password.txt`

VBoxManage clonevm "$BASE_VM_NAME" --name host1 --register
VBoxManage startvm host1 --type headless
echo "Waiting for the VM to boot..."
sleep 45

ip1=$(VBoxManage guestproperty get host1 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

echo "Installing Agents..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$ip1 << EOF
    sudo apt-get install -y gnupg curl

    curl -OL http://192.168.1.60:80/download/agent/automation/mongodb-mms-automation-agent-manager_107.0.10.8627-1_amd64.ubuntu1604.deb
    sudo dpkg -i mongodb-mms-automation-agent-manager_107.0.10.8627-1_amd64.ubuntu1604.deb

    sudo sed -i -e "s|^mmsGroupId=.*|mmsGroupId=66c4ea1193b15c2dc3813514|" /etc/mongodb-mms/automation-agent.config
    sudo sed -i -e "s|^mmsApiKey=.*|mmsApiKey=66c605801a85186721d3a9c744a8fad25c39d42a11b476ee9a110f4a|" /etc/mongodb-mms/automation-agent.config
    sudo sed -i -e "s|^mmsBaseUrl=.*|mmsBaseUrl=http://192.168.1.60:80|" /etc/mongodb-mms/automation-agent.config

    sudo mkdir -p /data; sudo chown mongodb:mongodb /data

    # setup firewall
    sudo ufw allow 27017
    sudo ufw allow 8080
    sudo ufw allow 80
    sudo ufw allow 22
    echo " y" | sudo ufw enable
    
    sudo systemctl start mongodb-mms-automation-agent.service
    sudo systemctl enable mongodb-mms-automation-agent.service

    sudo hostnamectl set-hostname host1
    sudo sed -i -e "s|ubuntu$|host1|" /etc/hosts
    # restart machine
EOF
sleep 1
done

echo "Done setting up first host!"

HOST_MACHINES=("host2" "host3")

echo "===== Host Machines..."
for NEW_VM in "${HOST_MACHINES[@]}"
do
VBoxManage clonevm "$BASE_VM_NAME" --name "$NEW_VM" --register
VBoxManage startvm "$NEW_VM" --type headless
done
echo "Waiting for the VMs to boot..."
sleep 45

for NEW_VM in "${HOST_MACHINES[@]}"
do
    sudo hostnamectl set-hostname $NEW_VM
    sudo sed -i -e "s|host1|$NEW_VM|" /etc/hosts
    # restart machine
done

echo "Done setting up hostnames. Restart all host machines!" 