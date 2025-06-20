#!/bin/bash

echo "Stopping and disabling RustDesk services..."

# Stop and disable services
sudo systemctl stop rustdesksignal.service 2>/dev/null
sudo systemctl stop rustdeskrelay.service 2>/dev/null
sudo systemctl stop gohttpserver.service 2>/dev/null

sudo systemctl disable rustdesksignal.service 2>/dev/null
sudo systemctl disable rustdeskrelay.service 2>/dev/null
sudo systemctl disable gohttpserver.service 2>/dev/null

# Remove service files
sudo rm -f /etc/systemd/system/rustdesksignal.service
sudo rm -f /etc/systemd/system/rustdeskrelay.service
sudo rm -f /etc/systemd/system/gohttpserver.service

# Reload systemd
sudo systemctl daemon-reload

echo "Removing RustDesk binaries and logs..."

# Remove binaries and logs
sudo rm -rf /opt/rustdesk
sudo rm -rf /var/log/rustdesk

# Remove gohttp server and logs (if used)
sudo rm -rf /opt/gohttp
sudo rm -rf /var/log/gohttp

echo "RustDesk server and optional HTTP service have been removed."
echo "Don't forget to clean up any firewall/NAT rules if needed."
