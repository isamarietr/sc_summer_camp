vi /etc/sudoers
ubuntu ALL=(ALL) NOPASSWD: ALL

sudo apt update && sudo apt upgrade
sudo apt install openssh-server
sudo systemctl enable --now ssh

sudo ufw allow ssh
