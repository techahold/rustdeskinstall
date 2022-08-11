#!/bin/bash

# Get Username
uname=$(whoami) # not used btw .. yet

sudo systemctl stop gohttpserver.service
sudo systemctl stop rustdesksignal.service
sudo systemctl stop rustdeskrelay.service


# identify OS
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    IDLIKE=$ID_LIKE
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    OS=SuSE
    VER=$(cat /etc/SuSe-release)
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS=RedHat
    VER=$(cat /etc/redhat-release)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

# Setup prereqs for server
# common named prereqs
prereq="curl wget unzip tar"
echo "Installing prerequisites"
if [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian" ]; then
    prereq+=" dnsutils"
    apt-get update
    apt-get install -y  "${prereq}" # git
elif [ "$OS" = "CentOS" ] || [ "$OS" = "RedHat" ]; then
    prereq+=" bind-utils"
    yum update -y
    yum install -y "${prereq}"   #  git
else
    echo "Unsupported OS"
    # here you could ask the user for permission to try and install anyway
    # if they say yes, then do the install
    # if they say no, exit the script
    exit 1
fi

cd /opt/rustdesk/

#Download latest version of Rustdesk
rm hbbs
rm hbbs
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-x64.zip"
unzip rustdesk-server-linux-x64.zip

sudo systemctl start rustdesksignal.service
sudo systemctl start rustdeskrelay.service

while ! [[ $CHECK_RUSTDESK_READY ]]; do
  CHECK_RUSTDESK_READY=$(sudo systemctl status rustdeskrelay.service | grep "Active: active (running)")
  echo -ne "Rustdesk Relay not ready yet...${NC}\n"
  sleep 3
done

rm rustdesk-server-linux-x64.zip

cd /opt/gohttp
GOHTTPLATEST=$(curl https://api.github.com/repos/codeskyblue/gohttpserver/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')
wget "https://github.com/codeskyblue/gohttpserver/releases/download/${GOHTTPLATEST}/gohttpserver_${GOHTTPLATEST}_linux_amd64.tar.gz"
tar -xf  gohttpserver_${GOHTTPLATEST}_linux_amd64.tar.gz

rm gohttpserver_${GOHTTPLATEST}_linux_amd64.tar.gz

sudo systemctl start gohttpserver.service

echo -e "Updates are complete"

