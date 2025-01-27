#!/bin/bash

# Get Username
uname=$(whoami) # not used btw .. yet

# Get current release version
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name" | awk -F'"' '{print $4}')
RDCURRENT=$(/opt/rustdesk/hbbr --version | sed -r 's/hbbr (.*)/\1/')

if [ $RDLATEST == $RDCURRENT ]; then
    echo "Same version no need to update."
    exit 0
fi

sudo systemctl stop gohttpserver.service
sudo systemctl stop rustdesksignal.service
sudo systemctl stop rustdeskrelay.service

ARCH=$(uname -m)

# identify OS
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    UPSTREAM_ID=${ID_LIKE,,}
    # Fallback to ID_LIKE if ID was not 'ubuntu' or 'debian'
    if [ "${UPSTREAM_ID}" != "debian" ] && [ "${UPSTREAM_ID}" != "ubuntu" ]; then
        UPSTREAM_ID="$(echo ${ID_LIKE,,} | sed s/\"//g | cut -d' ' -f1)"
    fi

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


# output ebugging info if $DEBUG set
if [ "$DEBUG" = "true" ]; then
    echo "OS: $OS"
    echo "VER: $VER"
    echo "UPSTREAM_ID: $UPSTREAM_ID"
    exit 0
fi


# Setup prereqs for server
# common named prereqs
PREREQ="curl wget unzip tar"
PREREQDEB="dnsutils"
PREREQRPM="bind-utils"

echo "Installing prerequisites"
if [ "${ID}" = "debian" ] || [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian" ]  || [ "${UPSTREAM_ID}" = "ubuntu" ] || [ "${UPSTREAM_ID}" = "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y  ${PREREQ} ${PREREQDEB} # git
elif [ "$OS" = "CentOS" ] || [ "$OS" = "RedHat" ]   || [ "${UPSTREAM_ID}" = "rhel" ] ; then
# opensuse 15.4 fails to run the relay service and hangs waiting for it
# needs more work before it can be enabled
# || [ "${UPSTREAM_ID}" = "suse" ]
    sudo yum update -y
    sudo yum install -y  ${PREREQ} ${PREREQRPM} # git
elif [ "${ID}" = "arch" ] || [ "${UPSTREAM_ID}" = "arch" ]; then
    sudo pacman -Syu
    sudo pacman -S ${PREREQ} ${PREREQARCH}
else
    echo "Unsupported OS"
    # here you could ask the user for permission to try and install anyway
    # if they say yes, then do the install
    # if they say no, exit the script
    exit 1
fi


if ! [ -e /opt/rustdesk  ]; then
        echo "No directory /opt/rustdesk found. No update of rustdesk possible (used install.sh script ?) "
        exit 4
else
        :
fi

cd /opt/rustdesk/

# remove any previous zip files
rm *.zip

echo "Upgrading Rustdesk Server"
if [ "${ARCH}" = "x86_64" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-amd64.zip"
unzip -j -o  rustdesk-server-linux-amd64.zip  "amd64/*" -d "/opt/rustdesk/"
elif [ "${ARCH}" = "armv7l" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-armv7.zip"
unzip -j -o  rustdesk-server-linux-armv7.zip  "armv7/*" -d "/opt/rustdesk/"
elif [ "${ARCH}" = "aarch64" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-arm64v8.zip"
unzip -j -o  rustdesk-server-linux-arm64v8.zip  "arm64v8/*" -d "/opt/rustdesk/"
fi

sudo systemctl start rustdesksignal.service
sudo systemctl start rustdeskrelay.service

while ! [[ $CHECK_RUSTDESK_READY ]]; do
  CHECK_RUSTDESK_READY=$(sudo systemctl status rustdeskrelay.service | grep "Active: active (running)")
  echo -ne "Rustdesk Relay not ready yet...${NC}\n"
  sleep 3
done

# chk if gotthp exists

if ! [ -e /opt/gohttp ]; then
        echo "No directory /opt/gohttp found. No update of gothhtp necessary."
        exit 4
else
        :
fi

cd /opt/gohttp
GOHTTPLATEST=$(curl https://api.github.com/repos/codeskyblue/gohttpserver/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')
if [ "${ARCH}" = "x86_64" ] ; then
wget "https://github.com/codeskyblue/gohttpserver/releases/download/${GOHTTPLATEST}/gohttpserver_${GOHTTPLATEST}_linux_amd64.tar.gz"
tar -xf  gohttpserver_${GOHTTPLATEST}_linux_amd64.tar.gz 
elif [ "${ARCH}" =  "aarch64" ] ; then
wget "https://github.com/codeskyblue/gohttpserver/releases/download/${GOHTTPLATEST}/gohttpserver_${GOHTTPLATEST}_linux_arm64.tar.gz"
tar -xf  gohttpserver_${GOHTTPLATEST}_linux_arm64.tar.gz
elif [ "${ARCH}" = "armv7l" ] ; then
echo "Go HTTP Server not supported on 32bit ARM devices"
exit 1
fi

sudo systemctl start gohttpserver.service

echo -e "Updates are complete"
