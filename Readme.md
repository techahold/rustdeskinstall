# Rustdesk server Install Script
Easy install Script for Rustdesk on linux, should work on any debian or centos based system supporting systemd. For Rustdesk - https://rustdesk.com

You can use Hetzner to test this with a $20 credit using this referal code https://hetzner.cloud/?ref=p6iUr7jEXmoB

# How to Install the server
Please setup your firewall on your server prior to running the script.

Make sure you have got access via ssh or otherwise setup prior setting up the firewall, command for UFW is.
```
ufw allow proto tcp from YOURIP to any port 22
```

If you have UFW installed use the following commands:
```
ufw allow 21115:21119/tcp
ufw allow 8000/tcp
ufw allow 21116/udp
sudo ufw enable
```

Run the following commands:
```
wget https://raw.githubusercontent.com/dinger1986/rustdeskinstall/master/install.sh
chmod +x install.sh
./install.sh
```

# Rustdesk windows powershell install script
Generates a powershell script for install grabbing WAN IP and Key currently in /opt/rustdesk but will be moved to a web url for easy deployment.
