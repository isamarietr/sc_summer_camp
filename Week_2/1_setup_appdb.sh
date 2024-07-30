#!/bin/bash

# Install sshpass

# Variables
BASE_VM_NAME="base_ubuntu"
PASSWORD=`cat ./password.txt`

MDB_MACHINES=("mdb1" "mdb2" "mdb3")

echo "Creating AppDB Machines..."
for NEW_VM in "${MDB_MACHINES[@]}"
do
VBoxManage clonevm "$BASE_VM_NAME" --name "$NEW_VM" --register
VBoxManage startvm "$NEW_VM" --type headless
done

for MDB_VM in "${MDB_MACHINES[@]}"
do

# Get the IP
mdb_ip=$(VBoxManage guestproperty get $MDB_VM "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

echo "Sending mongod.config..."
sshpass -p $PASSWORD scp -o StrictHostKeyChecking=no ./mongod.conf ubuntu@$mdb_ip:~/mongod.conf

echo "Installing MongoDB..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$mdb_ip << EOF

    # get mongodb EA binaries and install
    sudo apt-get install -y gnupg curl

    curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.com/apt/ubuntu jammy/mongodb-enterprise/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-enterprise-7.0.list

    sudo apt-get update 
    sudo apt-get install -y mongodb-database-tools mongodb-mongosh  mongodb-enterprise 

    sudo chown ubuntu /etc/mongod.conf
    sudo cp ~/mongod.conf /etc/mongod.conf

    sudo mkdir /data
    sudo chown -R mongodb:mongodb /data

    sudo openssl rand -base64 756 > ~/mongodb.key
    sudo mv ~/mongodb.key /etc/mongodb.key
    sudo chown -R mongodb:mongodb /etc/mongodb.key
    sudo chmod 400 /etc/mongodb.key

    # setup firewall
    sudo ufw allow 27017
    
    #start mongod
    sudo systemctl start mongod
    sudo systemctl enable mongod
EOF
sleep 1
done

echo "Done setting up all AppDB VMS!"

ip1=$(VBoxManage guestproperty get mdb1 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip2=$(VBoxManage guestproperty get mdb2 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip3=$(VBoxManage guestproperty get mdb3 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

echo "Initiating RS..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$ip1 << EOF
    echo " IPs.."
    echo $ip1
    echo $ip2
    echo $ip3
    mongosh $ip1 --eval  "rs.initiate({_id: 'rs0', members: [{ _id: 0, host: '$ip1:27017' },{ _id: 1, host: '$ip2:27017' },{ _id: 2, host: '$ip3:27017' }]})" 
EOF

echo "Connection string:"
echo "mongodb://$ip1:27017,$ip2:27017,$ip3:27017"