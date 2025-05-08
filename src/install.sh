#!/bin/bash

set -e

REPO_URL="https://github.com/iPmartNetwork/iPWG.git"
APP_DIR="/opt/iPWG"
SERVICE_NAME="ipwg-dashboard"

echo -e "\n\e[34m[+] Installing dependencies...\e[0m"
sudo apt update
sudo apt install -y python3 python3-pip git wireguard

echo -e "\n\e[34m[+] Cloning iPWG from GitHub...\e[0m"
sudo git clone "$REPO_URL" "$APP_DIR"

echo -e "\n\e[34m[+] Installing Python requirements...\e[0m"
cd "$APP_DIR"
pip3 install -r requirements.txt

echo -e "\n\e[34m[+] Creating systemd service...\e[0m"
cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null
[Unit]
Description=iPWG Dashboard
After=network.target

[Service]
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 $APP_DIR/src/dashboard.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo -e "\n\e[32m[✔] iPWG is installed and running at: http://<your-server-ip>:1000\e[0m"
