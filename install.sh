#!/bin/bash

# Get Username
uname=$(whoami)


# Setup prereqs for server
if [[ `which yum` ]]; then
   sudo yum install unzip -y
   sudo yum install bind-utils -y
elif [[ `which apt` ]]; then
   sudo apt-get update
   sudo apt-get install unzip -y
else
   echo "Unknown Platform, the install might fail"
fi

# Make Folder /opt/rustdesk/
if [ ! -d "/opt/rustdesk" ]; then
    echo "Creating /opt/rustdesk"
    sudo mkdir -p /opt/rustdesk/
fi
sudo chown ${uname} -R /opt/rustdesk
cd /opt/rustdesk/

#Download latest version of Rustdesk
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')
TMPFILE=$(mktemp)
sudo wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-x64.zip" -O ${TMPFILE}
unzip ${TMPFILE}

# Make Folder /var/log/rustdesk/
if [ ! -d "/var/log/rustdesk" ]; then
    echo "Creating /var/log/rustdesk"
    sudo mkdir -p /var/log/rustdesk/
fi
sudo chown ${uname} -R /var/log/rustdesk/

# Setup Systemd to launch hbbs
rustdesksignal="$(cat << EOF
[Unit]
Description=Rustdesk Signal Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/opt/rustdesk/hbbs -k _
WorkingDirectory=/opt/rustdesk/
User=${uname}
Group=${uname}
Restart=always
StandardOutput=append:/var/log/rustdesk/signalserver.log
StandardError=append:/var/log/rustdesk/signalserver.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${rustdesksignal}" | sudo tee /etc/systemd/system/rustdesksignal.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable rustdesksignal.service
sudo systemctl start rustdesksignal.service

# Setup Systemd to launch hbbr
rustdeskrelay="$(cat << EOF
[Unit]
Description=Rustdesk Relay Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/opt/rustdesk/hbbr -k _
WorkingDirectory=/opt/rustdesk/
User=${uname}
Group=${uname}
Restart=always
StandardOutput=append:/var/log/rustdesk/relayserver.log
StandardError=append:/var/log/rustdesk/relayserver.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${rustdeskrelay}" | sudo tee /etc/systemd/system/rustdeskrelay.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable rustdeskrelay.service
sudo systemctl start rustdeskrelay.service

#Get WAN IP
wanip=$(dig @resolver4.opendns.com myip.opendns.com +short)

pubname=$(find /opt/rustdesk -name *.pub)
key=$(cat ${pubname})

sudo rm ${TMPFILE}


echo -e "Your IP is ${wanip}"
echo -e "Your public key is ${key}"
echo -e "Install Rustdesk on your machines and change your public key and IP/DNS name to the above"


echo "Press any key to finish install"
while [ true ] ; do
read -t 3 -n 1
if [ $? = 0 ] ; then
exit ;
else
echo "waiting for the keypress"
fi
done
