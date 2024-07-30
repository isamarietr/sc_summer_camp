#!/bin/bash

# Install sshpass
# Make sure VMs have  openssh-server installed

# Variables
BASE_VM_NAME="base_ubuntu"
PASSWORD=`cat ./password.txt`

OPS_MACHINES=("ops1" "ops2" )
LB_MACHINES=("lb")

echo "===== Creating Ops Manager Machines..."
for NEW_VM in "${OPS_MACHINES[@]}"
do
VBoxManage clonevm "$BASE_VM_NAME" --name "$NEW_VM" --register
VBoxManage startvm "$NEW_VM" --type headless
done
echo "Waiting for the VMs to boot..."
sleep 45


echo "===== Creating LB Machines..."
for NEW_VM in "${LB_MACHINES[@]}"
do
VBoxManage clonevm "$BASE_VM_NAME" --name "$NEW_VM" --register
VBoxManage startvm "$NEW_VM" --type headless
done
echo "Waiting for the VMs to boot..."
sleep 45


ip1=$(VBoxManage guestproperty get ops1 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip2=$(VBoxManage guestproperty get ops2 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')
ip3=$(VBoxManage guestproperty get lb "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

for MDB_VM in "${OPS_MACHINES[@]}"
do

# Get the IP
mdb_ip=$(VBoxManage guestproperty get $MDB_VM "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

echo "Sending gen.key..."
sshpass -p $PASSWORD scp -o StrictHostKeyChecking=no ./gen.key ubuntu@$mdb_ip:~/gen.key

MONGO_URI="mongodb://192.168.1.225:27017,192.168.1.226:27017,192.168.1.227:27017" 

echo "Installing Ops Manager..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$mdb_ip << EOF

    sudo apt-get install -y gnupg curl
    sudo systemctl enable --now ssh

    # get installer
    curl -OL https://downloads.mongodb.com/on-prem-mms/deb/mongodb-mms-7.0.9.500.20240716T1711Z.amd64.deb

    sudo dpkg --install mongodb-mms-7.0.9.500.20240716T1711Z.amd64.deb

    sudo mv ~/gen.key /etc/mongodb-mms/gen.key
    sudo chown -R mongodb:mongodb /etc/mongodb-mms/gen.key

    sudo sed -i -e "s|^mongo.mongoUri=.*|mongo.mongoUri=$MONGO_URI|" /opt/mongodb/mms/conf/conf-mms.properties
    
    # setup firewall
    sudo ufw allow 27017
    sudo ufw allow 8080
    sudo ufw allow 22

    sudo systemctl start mongodb-mms
    sudo systemctl enable mongodb-mms

    # TODO: copy /etc/mongodb-mms/ gen.key
    
EOF
sleep 1
done


for MDB_VM in "${LB_MACHINES[@]}"
do

# Get the IP
mdb_ip=$(VBoxManage guestproperty get $MDB_VM "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

echo "Sending gen.key..."
sshpass -p $PASSWORD scp -o StrictHostKeyChecking=no ./gen.key ubuntu@$mdb_ip:~/gen.key

MONGO_URI="mongodb://192.168.1.225:27017,192.168.1.226:27017,192.168.1.227:27017" 

echo "Setting up Load Balancer rules..."
cat > load-balancer.conf << EOF
# Define which servers to include in the load balancing scheme. 
# It's best to use the servers' private IPs for better performance and security.
# You can find the private IPs at your UpCloud control panel Network section.
upstream backend {
   server $ip1:8080; 
   server $ip2:8080;
}

# This server accepts all traffic to port 80 and passes it to the upstream. 
# Notice that the upstream name and the proxy_pass need to match.

server {
   listen 80; 
   location / {
        proxy_redirect      off;
        proxy_set_header    X-Real-IP \$remote_addr;
        proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header    Host \$http_host;
		proxy_pass http://backend;
   }
}
EOF
sshpass -p $PASSWORD scp -o StrictHostKeyChecking=no ./load-balancer.conf ubuntu@$mdb_ip:~/load-balancer.conf

echo "Installing Load Balancer..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$mdb_ip << EOF

    sudo apt-get update
    sudo apt-get install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx

    sudo ufw allow http

    sudo rm -rf /etc/nginx/sites-enabled/default
    sudo mv ~/load-balancer.conf /etc/nginx/conf.d/load-balancer.conf
    sudo systemctl restart nginx

EOF
sleep 1
done
echo "Done setting up all AppDB VMS!"

LB_URL="http:\/\/$ip3:80" 

echo "Updating Ops Manager..."
for MDB_VM in "${OPS_MACHINES[@]}"
do

# Get the IP
mdb_ip=$(VBoxManage guestproperty get $MDB_VM "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{ print $2 }')

echo "Updating Ops Manager Config..."
sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no ubuntu@$mdb_ip << EOF

    sudo sed -i -e "s|^mmsBaseUrl=.*|mmsBaseUrl=$LB_URL|" /etc/mongodb-mms/automation-agent.config
    sudo systemctl restart mongodb-mms
    
EOF
sleep 1
done

echo "Done!"

echo "OPS1"
echo $ip1
echo "OPS2"
echo $ip2
echo "LB"
echo $ip3
