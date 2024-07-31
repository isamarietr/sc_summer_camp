sudo apt update && sudo apt install sshfs
sudo mkdir -p /mnt/shared
sudo sshfs -o allow_other,default_permissions ubuntu@$ip2:/home/ubuntu/shared /mnt/shared