#!/bin/bash

uname=$(whoami)
admintoken=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c8)


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

# Install Rustdesk
case ${OS,,} in
        # or case ${IDLIKE,,} in .. to support derivatives
    ubuntu|debian)
        # Debian/Ubuntu/etc.
          wget https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9.deb
         sudo apt install -fy ./rustdesk-1.1.9.deb
         ;;
      fedora|centos|redhat|amazon)
         # Red Hat, CentOS, etc.

         wget https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9.rpm
         sudo yum localinstall ./rustdesk-1.1.9.rpm
         # sudo dnf install -y ./rustdesk-1.1.9.rpm
         ;;
      *)
         echo "Unsupported OS"
         exit 1
         ;;
esac

rustdesk --password ${admintoken}
sudo pkill -f "rustdesk"

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

sudo chown ${uname}:${uname} /home/${uname}/.config/rustdesk/RustDesk2.toml


sudo systemctl restart rustdesk

echo "ID & Password for Rustdesk ${uname} are:"
grep -w id /home/${uname}/.config/rustdesk/RustDesk.toml
grep -w password /home/${uname}/.config/rustdesk/RustDesk.toml

echo "ID & Password for Rustdesk (root) are:"
sudo grep -w id /root/.config/rustdesk/RustDesk.toml
sudo grep -w password /root/.config/rustdesk/RustDesk.toml
