uname=$(whoami)
admintoken=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c8)

# Setup prereqs for server
if [[ $(which yum) ]]; then
   wget https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9.rpm
   sudo yum localinstall ./rustdesk-1.1.9.rpm
elif [[ $(which apt) ]]; then
   wget https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9.deb
   sudo dpkg -i rustdesk-1.1.9.deb
   sudo apt --fix-broken install -y
else
   echo "Unknown Platform, the install will fail"
   exit
fi

rustdesk --password ${admintoken}
pkill -f "rustdesk"

# Setup Rustdesk in user profile
rustdesktoml2a="$(cat << EOF
rendezvous_server = 'wanipreg'
nat_type = 1
serial = 3

[options]
rendezvous-servers = 'rs-ny.rustdesk.com,rs-sg.rustdesk.com,rs-cn.rustdesk.com'
key = 'keyreg'
custom-rendezvous-server = 'wanipreg'
api-server = 'https://wanipreg'
relay-server = 'wanipreg'
EOF
)"
echo "${rustdesktoml2a}" | sudo tee /home/${uname}/.config/rustdesk/RustDesk2.toml > /dev/null

# Setup Rustdesk in root profile
rustdesktoml2b="$(cat << EOF
rendezvous_server = 'wanipreg'
nat_type = 1
serial = 3

[options]
rendezvous-servers = 'rs-ny.rustdesk.com,rs-sg.rustdesk.com,rs-cn.rustdesk.com'
key = 'keyreg'
custom-rendezvous-server = 'wanipreg'
api-server = 'https://wanipreg'
relay-server = 'wanipreg'
EOF
)"
echo "${rustdesktoml2b}" | sudo tee /root/.config/rustdesk/RustDesk2.toml > /dev/null

chown ${uname}:${uname} /home/${uname}/.config/rustdesk/RustDesk2.toml 

systemctl restart rustdesk

cat /home/${uname}/.config/rustdesk/RustDesk.toml
sudo cat /root/.config/rustdesk/RustDesk.toml
