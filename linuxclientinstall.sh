#!/bin/bash

uname=$(whoami)
admintoken=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c8)
architecture=$(arch)

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

# Install Rustdesk
lversion=$(curl https://api.github.com/repos/rustdesk/rustdesk/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')

echo "Installing Rustdesk"
if [ "$OS" = "Ubuntu" ] || [ "${UPSTREAM_ID}" = "ubuntu" ]; then
    if [[ "$architecture" != @("x86_64"|"aarch64") ]]; then
        echo "Unsupported Architecture"
        exit 1
    fi
    if [ "$architecture" = "aarch64" ]; then
        sudo add-apt-repository -y universe
        sudo apt install -y libxdo3 curl libva-drm2 libva-x11-2
    fi
    wget https://github.com/rustdesk/rustdesk/releases/download/$lversion/rustdesk-$lversion-$architecture.deb
    sudo apt install -fy ./rustdesk-$lversion-$architecture.deb
elif [ "${ID}" = "debian" ] || [ "$OS" = "Debian" ]  || [ "${UPSTREAM_ID}" = "debian" ]; then
    wget https://github.com/rustdesk/rustdesk/releases/download/$lversion/rustdesk-$lversion-x86_64.deb
    sudo apt install -fy ./rustdesk-$lversion-x86_64.deb
elif [ "$OS" = "CentOS" ] || [ "$OS" = "RedHat" ] || [ "$OS" = "Fedora Linux" ]  || [ "${UPSTREAM_ID}" = "rhel" ] ; then
    wget https://github.com/rustdesk/rustdesk/releases/download/$lversion/rustdesk-$lversion-0.x86_64.rpm 
    sudo yum localinstall ./rustdesk-$lversion-0.x86_64.rpm
else
    echo "Unsupported OS"
    # here you could ask the user for permission to try and install anyway
    # if they say yes, then do the install
    # if they say no, exit the script
    exit 1
fi

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
