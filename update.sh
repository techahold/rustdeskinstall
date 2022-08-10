#!/bin/bash

# Get Username
uname=$(whoami)

sudo systemctl stop gohttpserver.service
sudo systemctl stop rustdesksignal.service
sudo systemctl stop rustdeskrelay.service


# Setup prereqs for server
if [[ $(which yum) ]]; then
   sudo yum install unzip -y
   sudo yum install bind-utils -y
elif [[ $(which apt) ]]; then
   sudo apt-get update
   sudo apt-get install unzip -y
   sudo apt-get install dnsutils -y
else
   echo "Unknown Platform, the install might fail"
fi

cd /opt/rustdesk/

#Download latest version of Rustdesk
rm hbbs
rm hbbs
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')
sudo wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-x64.zip"
unzip rustdesk-server-linux-x64.zip

sudo systemctl start rustdesksignal.service
sudo systemctl start rustdeskrelay.service

while ! [[ $CHECK_RUSTDESK_READY ]]; do
  CHECK_RUSTDESK_READY=$(sudo systemctl status rustdeskrelay.service | grep "Active: active (running)")
  echo -ne "Rustdesk Relay not ready yet...${NC}\n"
  sleep 3
done

sudo rm rustdesk-server-linux-x64.zip

cd /opt/gohttp
GOHTTPLATEST=$(curl https://api.github.com/repos/codeskyblue/gohttpserver/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')
sudo wget "https://github.com/codeskyblue/gohttpserver/releases/download/${GOHTTPLATEST}/gohttpserver_${GOHTTPLATEST}_linux_amd64.tar.gz"
tar -xf  gohttpserver_${GOHTTPLATEST}_linux_amd64.tar.gz

sudo rm gohttpserver_${GOHTTPLATEST}_linux_amd64.tar.gz

sudo systemctl start gohttpserver.service

echo -e "Updates are complete"

