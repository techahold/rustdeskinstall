#!/bin/bash

# Get Username
uname=$(whoami)


# Setup prereqs for server
apt update
apt install unzip -y

#Set firewall
ufw allow 21115:21119/tcp
ufw allow 21116/udp
sudo ufw enable

# Make Folder /opt/rustdesk/
if [ ! -d "/opt/rustdesk" ]; then
    echo "Creating /opt/rustdesk"
    mkdir -p /opt/rustdesk/
fi
cd /opt/rustdesk/

#Download latest version of Rustdesk
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')
TMPFILE=`mktemp`
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-x64.zip" -O ${TMPFILE}
unzip ${TMPFILE}

# Make Folder /var/log/rustdesk/
if [ ! -d "/var/log/rustdesk" ]; then
    echo "Creating /var/log/rustdesk"
    mkdir -p /var/log/rustdesk/
fi

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
sudo systemctl enable rustdeskrelay.service
sudo systemctl start rustdeskrelay.service

#Get WAN IP
wanip=$(dig @resolver4.opendns.com myip.opendns.com +short)

pubname=$(find /opt/rustdesk -name *.pub)
key=$(cat ${pubname})

rm ${TMPFILE}


printf >&2 "Your IP is ${wanip}"
printf >&2 "\n\n"
printf >&2 "Your public key is ${key}\n\n"
printf >&2 "\n\n"
printf >&2 "Install Rustdesk on your machines and change your public key and IP/DNS name to the above\n\n"
printf >&2 "\n\n"



echo "Press any key to finish install"
while [ true ] ; do
read -t 3 -n 1
if [ $? = 0 ] ; then
exit ;
else
echo "waiting for the keypress"
fi
done
