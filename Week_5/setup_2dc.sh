#!/bin/bash

# Install sshpass

# Variables
BASE_VM_NAME="base_ubuntu"
PASSWORD=`cat ./password.txt`

MDB_MACHINES=("mdb1" "mdb2" "mdb3" "mdb4" "mdb5" "mdb6")

echo "Creating AppDB Machines..."
for NEW_VM in "${MDB_MACHINES[@]}"
do
VBoxManage clonevm "$BASE_VM_NAME" --name "$NEW_VM" --register
VBoxManage startvm "$NEW_VM" --type headless
done
echo "Waiting for the VMs to boot..."
sleep 45

for MDB_VM in "${MDB_MACHINES[@]}"
do

# Get the IP
mdb_ip=$(VBoxManage guestproperty get $MDB_VM "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

echo "Sending mongod.config..."
sshpass -p $password scp -o StrictHostKeyChecking=no ./mongod.conf ubuntu@$mdb_ip:~/mongod.conf

echo "Installing MongoDB..."
sshpass -p $password ssh -o StrictHostKeyChecking=no ubuntu@$mdb_ip << EOF

    # get mongodb EA binaries and install
    sudo apt-get install -y gnupg curl

    curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.com/apt/ubuntu jammy/mongodb-enterprise/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-enterprise-7.0.list

    sudo apt-get update 
    sudo apt-get install -y mongodb-enterprise

    sudo chown ubuntu /etc/mongod.conf
    sudo cp ~/mongod.conf /etc/mongod.conf

    sudo mount /dev/vdb /data
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
ip4=$(VBoxManage guestproperty get mdb4 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip5=$(VBoxManage guestproperty get mdb5 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip6=$(VBoxManage guestproperty get mdb6 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

MDB_URI="mongodb://$ip1:27017,$ip2:27017,$ip3:27017,$ip4:27017,$ip5:27017,$ip6:27017" 
echo "Connection String:"
echo $MDB_URI
echo "Initiating RS..."
# mongosh $ip1 --eval 'use admin; db.createUser({user: "adminUser", pwd: "password123", roles: [{role: "userAdminAnyDatabase", db: "admin"}, "readWriteAnyDatabase"]})'
INIT_CMD="rs.initiate({_id: 'rs0', members: [{ _id: 0, host: '$ip1:27017' },{ _id: 1, host: '$ip2:27017' },{ _id: 2, host: '$ip3:27017' },{ _id: 3, host: '$ip4:27017' },{ _id: 4, host: '$ip5:27017'},{ _id: 5, host: '$ip6:27017', priority: 0, hidden: true }]})"
mongosh  $MDB_URI --eval  $INIT_CMD 

echo "Getting status.."
mongosh  $MDB_URI --eval  "rs.status()"
sleep 2

echo "Sutting down first 3 nodes..."
VBoxManage controlvm mdb1 acpipowerbutton
VBoxManage controlvm mdb2 acpipowerbutton
VBoxManage controlvm mdb3 acpipowerbutton

RECONFIG_CMD="var cfg = rs.conf(); cfg.members = [{ _id: 3, host: '$ip4:27017' },{ _id: 4, host: '$ip5:27017'},{ _id: 5, host: '$ip6:27017'}]; rs.reconfig(cfg, { force: true }); "
mongosh  $MDB_URI --eval  $RECONFIG_CMD

echo "Getting N E W status.."
mongosh  $MDB_URI --eval  "rs.status()"
sleep 2

echo "================================================================"
echo Init: $INIT_CMD
echo Reconfig: $RECONFIG_CMD
echo "================================================================"