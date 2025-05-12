#!/bin/bash

# Exit on error
set -e

# --- Helper Functions ---
ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# --- Log Functions ---
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_warning() {
    echo "[WARNING] $1"
}

# --- Check Root ---
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root. Please use sudo."
    exit 1
fi

# --- Variables ---
WG_CONF_DIR="/etc/wireguard"
IPWG_INSTALL_DIR_DEFAULT="/opt/iPWG"
IPWG_REPO_URL="https://github.com/iPmartNetwork/iPWG.git"
PYTHON_EXECUTABLE="python3"
PIP_EXECUTABLE="pip3"

# --- Prerequisites Installation ---
log_info "Updating package lists..."
if ! apt-get update -y; then
    log_error "Failed to update package lists. Please check your internet connection and repository configuration."
    exit 1
fi

log_info "Installing prerequisites (git, curl, python3, pip3, wireguard-tools, ufw)..."
if ! apt-get install -y git curl python3 python3-pip wireguard-tools ufw; then
    log_error "Failed to install prerequisite packages. Please check for errors above."
    exit 1
fi

# --- WireGuard Configuration ---
log_info "Starting WireGuard configuration..."

read -p "Enter WireGuard interface name (e.g., wg0): " WG_IFACE
WG_IFACE=${WG_IFACE:-wg0} # Default to wg0 if empty
WG_CONF_FILE="$WG_CONF_DIR/$WG_IFACE.conf"
SERVER_PRIVKEY=""
SERVER_PUBKEY=""

# Check if config already exists
if [ -f "$WG_CONF_FILE" ]; then
    if ! ask_yes_no "WireGuard configuration file $WG_CONF_FILE already exists. Overwrite?"; then
        log_info "Skipping WireGuard configuration as file exists and user chose not to overwrite."
        # Try to read existing public key if possible (simplistic, assumes key is on one line)
        if grep -q "PrivateKey" "$WG_CONF_FILE"; then
             EXISTING_PRIVKEY=$(grep "PrivateKey" "$WG_CONF_FILE" | cut -d'=' -f2 | xargs)
             if [ -n "$EXISTING_PRIVKEY" ]; then
                SERVER_PUBKEY=$(echo "$EXISTING_PRIVKEY" | wg pubkey)
                log_info "Existing WireGuard server public key: $SERVER_PUBKEY"
             fi
        fi
    else
        rm -f "$WG_CONF_FILE"
        log_info "Removed existing WireGuard configuration file: $WG_CONF_FILE"
    fi
fi

if [ ! -f "$WG_CONF_FILE" ]; then
    read -p "Enter WireGuard server listen port (default: 51820): " WG_LISTEN_PORT
    WG_LISTEN_PORT=${WG_LISTEN_PORT:-51820}

    read -p "Enter WireGuard server private IP address with CIDR (e.g., 10.0.0.1/24): " WG_SERVER_IP
    while [[ -z "$WG_SERVER_IP" ]]; do
        read -p "Server IP address cannot be empty. Please enter (e.g., 10.0.0.1/24): " WG_SERVER_IP
    done

    read -p "Enter DNS server for clients (default: 1.1.1.1): " WG_DNS
    WG_DNS=${WG_DNS:-1.1.1.1}

    # Detect public network interface
    DEFAULT_PUBLIC_NET_INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
    read -p "Enter the public network interface name (default: $DEFAULT_PUBLIC_NET_INTERFACE): " PUBLIC_NET_INTERFACE
    PUBLIC_NET_INTERFACE=${PUBLIC_NET_INTERFACE:-$DEFAULT_PUBLIC_NET_INTERFACE}
    while [[ -z "$PUBLIC_NET_INTERFACE" ]] || ! ip link show "$PUBLIC_NET_INTERFACE" > /dev/null 2>&1; do
        log_error "Network interface '$PUBLIC_NET_INTERFACE' not found or invalid."
        read -p "Please enter a valid public network interface name: " PUBLIC_NET_INTERFACE
    done


    log_info "Generating WireGuard server keys..."
    SERVER_PRIVKEY=$(wg genkey)
    SERVER_PUBKEY=$(echo "$SERVER_PRIVKEY" | wg pubkey)

    log_info "Creating WireGuard configuration file: $WG_CONF_FILE"
    mkdir -p "$WG_CONF_DIR"
    touch "$WG_CONF_FILE"
    chmod 600 "$WG_CONF_FILE"

    cat > "$WG_CONF_FILE" << EOF
[Interface]
Address = $WG_SERVER_IP
ListenPort = $WG_LISTEN_PORT
PrivateKey = $SERVER_PRIVKEY
DNS = $WG_DNS
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $PUBLIC_NET_INTERFACE -j MASQUERADE; iptables -A FORWARD -o %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $PUBLIC_NET_INTERFACE -j MASQUERADE; iptables -D FORWARD -o %i -j ACCEPT
EOF
    log_info "WireGuard server public key: $SERVER_PUBKEY"
    log_info "Add this public key to your clients."

    # Enable IP forwarding
    log_info "Enabling IP forwarding..."
    sysctl -w net.ipv4.ip_forward=1
    if ! grep -q "^net.ipv4.ip_forward=1$" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    sysctl -p

    # Firewall configuration (UFW)
    log_info "Configuring firewall (UFW)..."
    ufw allow $WG_LISTEN_PORT/udp
    ufw allow ssh
    # Allow traffic forwarding for WireGuard interface
    if ufw status | grep -qw active; then
        # Insert rule for FORWARD chain if UFW is active and manages it
        # This might require editing /etc/default/ufw and /etc/ufw/before.rules for persistent FORWARD policy
        log_info "Make sure to set DEFAULT_FORWARD_POLICY=\"ACCEPT\" in /etc/default/ufw"
        log_info "And add appropriate rules to /etc/ufw/before.rules if not already present for NAT."
        # A simpler approach for UFW and WireGuard often involves direct iptables rules (as in PostUp/PostDown)
        # and ensuring UFW doesn't block the established connections or related traffic.
    fi
    
    # Disable and re-enable UFW to apply changes
    ufw disable
    echo "y" | ufw enable

    log_info "Enabling and starting WireGuard service for $WG_IFACE..."
    systemctl enable wg-quick@$WG_IFACE
    systemctl restart wg-quick@$WG_IFACE # Use restart to ensure it picks up new config
    log_info "WireGuard service for $WG_IFACE started."
else
    log_info "$WG_CONF_FILE exists and was not overwritten. Assuming WireGuard is already configured and running."
    if systemctl is-active --quiet wg-quick@$WG_IFACE; then
        log_info "WireGuard service wg-quick@$WG_IFACE is active."
    else
        log_warning "WireGuard service wg-quick@$WG_IFACE is not active. You might need to start it manually: systemctl start wg-quick@$WG_IFACE"
    fi
fi

# --- iPWG Dashboard Installation ---
log_info "Starting iPWG Dashboard installation..."
read -e -p "Enter installation directory for iPWG Dashboard (default: $IPWG_INSTALL_DIR_DEFAULT): " IPWG_INSTALL_DIR_INPUT
IPWG_INSTALL_DIR="${IPWG_INSTALL_DIR_INPUT:-$IPWG_INSTALL_DIR_DEFAULT}"

if [ -d "$IPWG_INSTALL_DIR" ]; then
    if [ "$(ls -A $IPWG_INSTALL_DIR)" ]; then # Check if directory is not empty
        if ask_yes_no "$IPWG_INSTALL_DIR already exists and is not empty. Do you want to remove its contents and reinstall?"; then
            log_info "Removing existing contents from: $IPWG_INSTALL_DIR"
            rm -rf "$IPWG_INSTALL_DIR"/* "$IPWG_INSTALL_DIR"/.[!.]* # Remove all files and hidden files
            mkdir -p "$IPWG_INSTALL_DIR" # Ensure directory exists after rm
        else
            log_info "Using existing directory: $IPWG_INSTALL_DIR. Attempting to update."
            cd "$IPWG_INSTALL_DIR"
            if [ -d ".git" ]; then
                log_info "Updating repository with git pull..."
                git pull
            else
                log_warning "No .git directory found in $IPWG_INSTALL_DIR. Cannot update with git pull. Proceeding with existing files."
            fi
        fi
    fi
else
    mkdir -p "$IPWG_INSTALL_DIR"
fi


if [ ! -d "$IPWG_INSTALL_DIR/.git" ]; then # Clone only if not already a git repo or was cleaned
    log_info "Cloning iPWG repository to $IPWG_INSTALL_DIR..."
    git clone "$IPWG_REPO_URL" "$IPWG_INSTALL_DIR"
fi

cd "$IPWG_INSTALL_DIR"

# Navigate to the src directory where requirements and service file are expected
IPWG_SRC_DIR="$IPWG_INSTALL_DIR/src"
if [ -d "$IPWG_SRC_DIR" ]; then
    cd "$IPWG_SRC_DIR"
else
    log_warning "Subdirectory 'src' not found in $IPWG_INSTALL_DIR. Assuming relevant files are in the root."
    IPWG_SRC_DIR="$IPWG_INSTALL_DIR" # Point to the root of the install dir
fi

if [ ! -f "requirements.txt" ]; then
    log_error "Could not find requirements.txt in $PWD. Please check the repository structure or installation path."
    exit 1
fi

log_info "Installing Python dependencies from requirements.txt using $PIP_EXECUTABLE..."
if ! $PIP_EXECUTABLE install -r requirements.txt; then
    log_error "Failed to install Python dependencies. Please check for errors."
    exit 1
fi

log_info "Setting up iPWG Dashboard service..."
SERVICE_FILE_NAME="iPWGDashboard.service"
SYSTEMD_SERVICE_PATH="/etc/systemd/system/$SERVICE_FILE_NAME"

# The service file from the repo might be in IPWG_SRC_DIR or IPWG_INSTALL_DIR/src
# Let's assume it's in IPWG_SRC_DIR (current directory if src exists, or install_dir if not)
REPO_SERVICE_FILE_PATH="$IPWG_SRC_DIR/$SERVICE_FILE_NAME"

if [ ! -f "$REPO_SERVICE_FILE_PATH" ]; then
    log_error "Original service file $REPO_SERVICE_FILE_PATH not found. Cannot set up the service automatically based on it."
    log_info "A generic service file will be created."
    # Create a generic service file content
    cat > "$SYSTEMD_SERVICE_PATH" << EOF
[Unit]
Description=iPWG Dashboard
After=network.target wg-quick@$WG_IFACE.service

[Service]
User=root
Group=root
WorkingDirectory=$IPWG_SRC_DIR
ExecStart=$PYTHON_EXECUTABLE -m gunicorn --workers 3 --bind unix:$IPWG_SRC_DIR/iPWGDashboard.sock -m 007 dashboard:app --config $IPWG_SRC_DIR/gunicorn.conf.py
Restart=always
RestartSec=10
StandardOutput=append:/var/log/ipwgdashboard.log
StandardError=append:/var/log/ipwgdashboard.err.log

[Install]
WantedBy=multi-user.target
EOF
    log_info "Created generic systemd service file: $SYSTEMD_SERVICE_PATH"

else
    log_info "Using service file template from repository: $REPO_SERVICE_FILE_PATH"
    # Modify the existing service file from the repo to ensure paths are correct
    # Replace WorkingDirectory and parts of ExecStart
    # Ensure dashboard:app and gunicorn.conf.py are correctly referenced relative to WorkingDirectory
    sed -e "s|^WorkingDirectory=.*|WorkingDirectory=$IPWG_SRC_DIR|" \
        -e "s|ExecStart=/usr/bin/gunicorn|ExecStart=$PYTHON_EXECUTABLE -m gunicorn|" \
        -e "s|unix:iPWGDashboard.sock|unix:$IPWG_SRC_DIR/iPWGDashboard.sock|" \
        -e "s|--config gunicorn.conf.py|--config $IPWG_SRC_DIR/gunicorn.conf.py|" \
        -e "s|dashboard:app|dashboard:app|" \
        "$REPO_SERVICE_FILE_PATH" > "$SYSTEMD_SERVICE_PATH"

    # Add logging and ensure After directive includes WireGuard service
    if ! grep -q "wg-quick@$WG_IFACE.service" "$SYSTEMD_SERVICE_PATH"; then
        sed -i "/^After=network.target/ s/$/ wg-quick@$WG_IFACE.service/" "$SYSTEMD_SERVICE_PATH"
    fi
    if ! grep -q "StandardOutput=" "$SYSTEMD_SERVICE_PATH"; then
        sed -i "/^RestartSec=.*/a StandardOutput=append:/var/log/ipwgdashboard.log\nStandardError=append:/var/log/ipwgdashboard.err.log" "$SYSTEMD_SERVICE_PATH"
    fi
    log_info "Copied and modified systemd service file to: $SYSTEMD_SERVICE_PATH"
fi


# Ensure gunicorn.conf.py and dashboard.py (for dashboard:app) exist
if [ ! -f "$IPWG_SRC_DIR/gunicorn.conf.py" ]; then
    log_warning "$IPWG_SRC_DIR/gunicorn.conf.py not found. The service might fail."
fi
if [ ! -f "$IPWG_SRC_DIR/dashboard.py" ]; then
    log_warning "$IPWG_SRC_DIR/dashboard.py not found. The 'dashboard:app' module might not be available, service could fail."
fi


log_info "Reloading systemd daemon..."
systemctl daemon-reload

log_info "Enabling iPWG Dashboard service ($SERVICE_FILE_NAME)..."
systemctl enable $SERVICE_FILE_NAME

log_info "Starting iPWG Dashboard service ($SERVICE_FILE_NAME)..."
systemctl restart $SERVICE_FILE_NAME # Use restart to ensure it picks up new config

# Check status
log_info "Waiting a few seconds for the service to start..."
sleep 5
if systemctl is-active --quiet $SERVICE_FILE_NAME; then
    log_info "iPWG Dashboard service is active."
else
    log_error "iPWG Dashboard service failed to start. Check logs for details:"
    log_error "journalctl -u $SERVICE_FILE_NAME"
    log_error "cat /var/log/ipwgdashboard.log"
    log_error "cat /var/log/ipwgdashboard.err.log"
fi

log_info "---------------------------------------------------------------------"
log_info "Installation Complete!"
if [ -n "$SERVER_PUBKEY" ]; then
    log_info "WireGuard interface '$WG_IFACE' is configured."
    log_info "WireGuard server public key: $SERVER_PUBKEY (add this to clients)"
else
    log_info "WireGuard configuration was skipped or public key could not be retrieved. Please check manually."
fi
log_info "iPWG Dashboard is installed in $IPWG_INSTALL_DIR (application source in $IPWG_SRC_DIR)"
log_info "iPWG Dashboard service ($SERVICE_FILE_NAME) is configured."
log_info "To check dashboard status: systemctl status $SERVICE_FILE_NAME"
log_info "Dashboard logs can be found at /var/log/ipwgdashboard.log, /var/log/ipwgdashboard.err.log, or via journalctl -u $SERVICE_FILE_NAME"
log_info "You might need to configure a reverse proxy (e.g., Nginx) to access the dashboard via a domain and HTTPS."
log_info "The dashboard should be running on a local socket: $IPWG_SRC_DIR/iPWGDashboard.sock"
log_info "---------------------------------------------------------------------"

exit 0
