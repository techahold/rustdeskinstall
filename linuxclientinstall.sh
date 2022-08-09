uname=$(users)
admintoken=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c8)

# Setup prereqs for server
if [[ $(which yum) ]]; then
   wget https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9.rpm
   sudo yum localinstall ./rustdesk-1.1.9.rpm
elif [[ $(which apt) ]]; then
   wget https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9.deb
   sudo dpkg -i rustdesk-1.1.9.deb
   sudo apt install -fy ./rustdesk-1.1.9.deb
else
   echo "Unknown Platform, the install will fail"
   exit
fi

su ${uname} -c "DISPLAY=:0 rustdesk --password ${admintoken}"

# Setup Systemd to launch hbbs
rustdesksignal="$(cat << EOF
rendezvous_server = 'rs-ny.rustdesk.com'
nat_type = 1
serial = 3

[options]
rendezvous-servers = 'rs-ny.rustdesk.com,rs-sg.rustdesk.com,rs-cn.rustdesk.com'
key = ''
custom-rendezvous-server = ''
api-server = 'https://'
relay-server = ''
EOF
)"
echo "${rustdesksignal}" | sudo tee /home/${uname}/.config/rustdesk/RustDesk2.toml > /dev/null

chown ${uname}:${uname} /home/${uname}/.config/rustdesk/RustDesk2.toml 

pkill -f "rustdesk"

systemctl restart rustdesk

cat /home/${uname}/.config/rustdesk/RustDesk.toml
