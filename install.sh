#!/bin/bash

# Get Username
uname=$(whoami)
admintoken=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)

# Choice for DNS or IP
PS3='Choose your preferred option, IP or DNS/Domain:'
WAN=("IP" "DNS/Domain")
select WANOPT in "${WAN[@]}"; do
case $WANOPT in
"IP")
wanip=$(dig @resolver4.opendns.com myip.opendns.com +short)
echo $wanip
break
;;

"DNS/Domain")
echo -ne "Enter your preferred domain/dns address ${NC}: "
read wanip
echo $wanip
break
;;
*) echo "invalid option $REPLY";;
esac
done

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

# Make Folder /opt/rustdesk/
if [ ! -d "/opt/rustdesk" ]; then
    echo "Creating /opt/rustdesk"
    sudo mkdir -p /opt/rustdesk/
fi
sudo chown "${uname}" -R /opt/rustdesk
cd /opt/rustdesk/

#Download latest version of Rustdesk
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')
TMPFILE=$(mktemp)
sudo wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-x64.zip" -O "${TMPFILE}"
unzip "${TMPFILE}"

# Make Folder /var/log/rustdesk/
if [ ! -d "/var/log/rustdesk" ]; then
    echo "Creating /var/log/rustdesk"
    sudo mkdir -p /var/log/rustdesk/
fi
sudo chown "${uname}" -R /var/log/rustdesk/

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

while ! [[ $CHECK_RUSTDESK_READY ]]; do
  CHECK_RUSTDESK_READY=$(sudo systemctl status rustdeskrelay.service | grep "Active: active (running)")
  echo -ne "Rustdesk Relay not ready yet...${NC}\n"
  sleep 3
done

pubname=$(find /opt/rustdesk -name *.pub)
key=$(cat "${pubname}")

sudo rm "${TMPFILE}"

# Create windows install script 
wget https://raw.githubusercontent.com/dinger1986/rustdeskinstall/master/WindowsAgentAIOInstall.ps1
sudo sed -i "s|wanipreg|${wanip}|g" WindowsAgentAIOInstall.ps1
sudo sed -i "s|keyreg|${key}|g" WindowsAgentAIOInstall.ps1

# Create linux install script 
wget https://raw.githubusercontent.com/dinger1986/rustdeskinstall/master/linuxclientinstall.sh
sudo sed -i "s|wanipreg|${wanip}|g" linuxclientinstall.sh
sudo sed -i "s|keyreg|${key}|g" linuxclientinstall.sh

# Download and install gohttpserver
# Make Folder /opt/gohttp/
if [ ! -d "/opt/gohttp" ]; then
    echo "Creating /opt/gohttp"
    sudo mkdir -p /opt/gohttp/
	sudo mkdir -p /opt/gohttp/public
fi
sudo chown "${uname}" -R /opt/gohttp
cd /opt/gohttp
GOHTTPLATEST=$(curl https://api.github.com/repos/codeskyblue/gohttpserver/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')
TMPFILE=$(mktemp)
sudo wget "https://github.com/codeskyblue/gohttpserver/releases/download/${GOHTTPLATEST}/gohttpserver_${GOHTTPLATEST}_linux_amd64.tar.gz" -O "${TMPFILE}"
tar -xf  "${TMPFILE}"

# Copy Rustdesk install scripts to folder
mv /opt/rustdesk/WindowsAgentAIOInstall.ps1 /opt/gohttp/public/
mv /opt/rustdesk/linuxclientinstall.sh /opt/gohttp/public/

# Make gohttp log folders
if [ ! -d "/var/log/gohttp" ]; then
    echo "Creating /var/log/gohttp"
    sudo mkdir -p /var/log/gohttp/
fi
sudo chown "${uname}" -R /var/log/gohttp/

sudo rm "${TMPFILE}"

# Setup Systemd to launch Go HTTP Server
gohttpserver="$(cat << EOF
[Unit]
Description=Go HTTP Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/opt/gohttp/gohttpserver -r ./public --port 8000 --auth-type http --auth-http admin:${admintoken}
WorkingDirectory=/opt/gohttp/
User=${uname}
Group=${uname}
Restart=always
StandardOutput=append:/var/log/gohttp/gohttpserver.log
StandardError=append:/var/log/gohttp/gohttpserver.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${gohttpserver}" | sudo tee /etc/systemd/system/gohttpserver.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable gohttpserver.service
sudo systemctl start gohttpserver.service


echo -e "Your IP is ${wanip}"
echo -e "Your public key is ${key}"
echo -e "Install Rustdesk on your machines and change your public key and IP/DNS name to the above"
echo -e "You can access your install scripts for clients by going to http://${wanip}:8000"
echo -e "Username is admin and password is ${admintoken}"

echo "Press any key to finish install"
while [ true ] ; do
read -t 3 -n 1
if [ $? = 0 ] ; then
exit ;
else
echo "waiting for the keypress"
fi
done
