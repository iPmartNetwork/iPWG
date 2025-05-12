#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")

RED='\033[0;31m'
GREEN='\033[1;92m'
YELLOW='\033[1;33m'
BLUE='\033[96m'
CYAN='\033[0;36m'
NC='\033[0m' 
INFO="\033[96m"      
SUCCESS="\033[1;92m"    
WARNING="\e[33m"   
ERROR="\e[31m"      

install_requirements() {
    echo -e "\033[92mRequirements\033[0m"
    echo -e '\033[93m══════════════════════════════════\033[0m'

    echo -e "${INFO}[INFO]${YELLOW}Installing required Stuff...${NC}"
    echo -e '\033[93m══════════════════════════════════\033[0m'

    sudo apt update && sudo apt install -y python3 python3-pip python3-venv git redis nftables iptables wireguard-tools iproute2 \
        fonts-dejavu certbot curl software-properties-common wget || {
        echo -e "${ERROR}Installation failed. Ensure you are using root privileges.${NC}"
        return 1
    }

    echo -e "${INFO}[INFO]${YELLOW}Starting Redis server...${NC}"
    sudo systemctl enable redis-server.service
    sudo systemctl start redis-server.service || {
        echo -e "${ERROR}Couldn't start Redis server. Please check system logs.${NC}"
        return 1
    }

    echo -e "${SUCCESS}[SUCCESS]All required stuff have been installed successfully.${NC}"
    echo -e "${CYAN}Press Enter to continue...${NC}" && read
    return 0
}


setup_virtualenv() {
    echo -e "\033[92mVirtual env Setup\033[0m"
    echo -e '\033[92m══════════════════════════════════\033[0m'
    echo -e "${INFO}[INFO]${YELLOW}Setting up Virtual Env...${NC}"

    PYTHON_BIN=$(which python3)
    if [ -z "$PYTHON_BIN" ]; then
        echo -e "${ERROR}Python3 is not installed or not in PATH. install Python3.${NC}"
        return 1
    fi

    echo -e "${INFO}[INFO]${YELLOW}Using Python binary: $PYTHON_BIN${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Creating virtual env...${NC}"
    "$PYTHON_BIN" -m venv "$SCRIPT_DIR/venv" || {
        echo -e "${ERROR}Couldn't create virtual env. Plz check Python installation and permissions.${NC}"
        return 1
    }

    echo -e "${INFO}[INFO]${YELLOW}Activating virtual env...${NC}"
    source "$SCRIPT_DIR/venv/bin/activate" || {
        echo -e "${ERROR}Couldn't activate virtual environment. Please check if the virtualenv module is installed.${NC}"
        return 1
    }

    echo -e "${INFO}[INFO]${YELLOW}Upgrading pip and installing stuff...${NC}"
    pip install --upgrade pip || {
        echo -e "${ERROR}Couldn't upgrade pip. Change DNS.${NC}"
        deactivate
        return 1
    }

    pip install \
        python-dotenv \
        python-telegram-bot \
        aiohttp \
        matplotlib \
        qrcode \
        "python-telegram-bot[job-queue]" \
        pyyaml \
        flask-session \
        Flask \
        SQLAlchemy \
        Flask-Limiter \
        Flask-Bcrypt \
        Flask-Caching \
        jsonschema \
        psutil \
        requests \
        pynacl \
        apscheduler \
        redis \
        werkzeug \
        jinja2 \
        fasteners \
        gunicorn \
        cryptography \
        Pillow \
        arabic-reshaper \
        python-bidi \
        pytz \
        jdatetime || {
            echo -e "${ERROR}Couldn't install Python requirements. check the error messages and try again.${NC}"
            deactivate
            return 1
        }


    echo -e "${INFO}[INFO]${YELLOW}Installing stuff...${NC}"
    sudo apt-get update || {
        echo -e "${ERROR}Couldn't update package list. Please check your DNS or network connection.${NC}"
        deactivate
        return 1
    }

    sudo apt-get install -y libsystemd-dev || {
        echo -e "${ERROR}Couldn't install libsystemd-dev. Check your package manager or system settings.${NC}"
        deactivate
        return 1
    }

    echo -e "${SUCCESS}[SUCCESS]Virtual env set up successfully.${NC}"
    deactivate
    echo -e "${CYAN}Press Enter to exit...${NC}" && read
    return 0
}


setup_permissions() {
    echo -e "\033[92mRead & Write permissions\033[0m"
    echo -e '\033[92m══════════════════════════════════\033[0m'
    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for files & directories...${NC}"
    echo -e '\033[93m══════════════════════════════════\033[0m'

    CONFIG_FILE="$SCRIPT_DIR/config.yaml"
    DB_DIR="$SCRIPT_DIR/db"
    BACKUPS_DIR="$SCRIPT_DIR/backups"
    TELEGRAM_DIR="$SCRIPT_DIR/telegram"
    TELEGRAM_YAML="$TELEGRAM_DIR/telegram.yaml"
    TELEGRAM_JSON="$TELEGRAM_DIR/config.json"
    INSTALL_PROGRESS_JSON="$SCRIPT_DIR/install_progress.json"
    STATIC_FONTS_DIR="$SCRIPT_DIR/static/fonts"

    mkdir -p "$DB_DIR"
    mkdir -p "$BACKUPS_DIR"
    mkdir -p "$TELEGRAM_DIR"
    mkdir -p "$STATIC_FONTS_DIR"
    touch "$CONFIG_FILE" 2>/dev/null
    touch "$TELEGRAM_YAML" 2>/dev/null
    touch "$TELEGRAM_JSON" 2>/dev/null
    touch "$INSTALL_PROGRESS_JSON" 2>/dev/null


    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $CONFIG_FILE...${NC}"
    chmod 644 "$CONFIG_FILE" 2>/dev/null || echo -e "${WARNING}Warning: Couldn't set permissions for $CONFIG_FILE.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $DB_DIR...${NC}"
    chmod -R 600 "$DB_DIR" 2>/dev/null || echo -e "${WARNING}Warning: Couldn't set permissions for $DB_DIR.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $BACKUPS_DIR...${NC}"
    chmod -R 700 "$BACKUPS_DIR" 2>/dev/null || echo -e "${WARNING}Warning: Couldn't set permissions for $BACKUPS_DIR.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $TELEGRAM_YAML...${NC}"
    chmod 644 "$TELEGRAM_YAML" 2>/dev/null || echo -e "${WARNING}Warning: $TELEGRAM_YAML not found or permission error.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $TELEGRAM_JSON...${NC}"
    chmod 644 "$TELEGRAM_JSON" 2>/dev/null || echo -e "${WARNING}Warning: $TELEGRAM_JSON not found or permission error.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $INSTALL_PROGRESS_JSON...${NC}"
    chmod 644 "$INSTALL_PROGRESS_JSON" 2>/dev/null || echo -e "${WARNING}Warning: $INSTALL_PROGRESS_JSON not found or permission error.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $SCRIPT_DIR/setup.sh...${NC}"
    chmod 744 "$SCRIPT_DIR/setup.sh" 2>/dev/null || echo -e "${WARNING}Warning: setup.sh not found or permission error.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $SCRIPT_DIR/install_telegram.sh...${NC}"
    chmod 744 "$SCRIPT_DIR/install_telegram.sh" 2>/dev/null || echo -e "${WARNING}Warning: install_telegram.sh not found or permission error.${NC}"

    echo -e "${INFO}[INFO]${YELLOW}Setting permissions for $STATIC_FONTS_DIR...${NC}"
    chmod -R 644 "$STATIC_FONTS_DIR" 2>/dev/null || echo -e "${WARNING}Warning: $STATIC_FONTS_DIR not found or permission error.${NC}"

    if [ -d "/etc/wireguard" ]; then
        echo -e "${INFO}[INFO]${YELLOW}Setting permissions for /etc/wireguard...${NC}"
        sudo chmod -R 755 /etc/wireguard || echo -e "${ERROR}Couldn't set permissions for /etc/wireguard. use sudo -i.${NC}"
    else
        echo -e "${WARNING}/etc/wireguard directory does not exist. It will be created during WireGuard setup.${NC}"
    fi

    echo -e "${INFO}[INFO]${YELLOW}Checking permissions for other directories...${NC}"

    find "$SCRIPT_DIR" -type f ! -path "$SCRIPT_DIR/venv/*" -exec chmod 644 {} \; 2>/dev/null || echo -e "${WARNING}Could not update file permissions in $SCRIPT_DIR.${NC}"
    find "$SCRIPT_DIR" -type d ! -path "$SCRIPT_DIR/venv/*" -exec chmod 755 {} \; 2>/dev/null || echo -e "${WARNING}Could not update directory permissions in $SCRIPT_DIR.${NC}"


    echo -e "${SUCCESS}[SUCCESS]Permissions have been set successfully.${NC}"
    echo -e "${CYAN}Press Enter to continue...${NC}" && read
    return 0
}

setup_tls() {
    echo -e '\033[93m══════════════════════════════════\033[0m'
    echo -e "${YELLOW}Do you want to ${GREEN}enable TLS${YELLOW}? ${GREEN}[yes]${NC}/${RED}[no]${NC}: ${NC} \c"

    while true; do
        read -e ENABLE_TLS
        ENABLE_TLS=$(echo "$ENABLE_TLS" | tr '[:upper:]' '[:lower:]')  
        
        if [[ "$ENABLE_TLS" == "yes" || "$ENABLE_TLS" == "no" ]]; then
            echo -e "${INFO}[INFO] TLS enabled: ${GREEN}$ENABLE_TLS${NC}" 
            break
        else
            echo -e "${RED}Wrong input. Please type ${GREEN}yes${RED} or ${RED}no${NC}: \c"
        fi
    done

    if [ "$ENABLE_TLS" = "yes" ]; then
        while true; do
            echo -e "${YELLOW}Enter your ${GREEN}Sub-domain name${YELLOW}:${NC} \c"
            read -e DOMAIN_NAME
            if [ -n "$DOMAIN_NAME" ]; then
                echo -e "${INFO}[INFO] Sub-domain set to: ${GREEN}$DOMAIN_NAME${NC}" 
                break
            else
                echo -e "${RED}Sub-domain name cannot be empty. Please try again.${NC}"
            fi
        done

        while true; do
            echo -e "${YELLOW}Enter your ${GREEN}Email address${YELLOW}:${NC} \c"
            read -e EMAIL
            if [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                echo -e "${INFO}[INFO] Email set to: ${GREEN}$EMAIL${NC}" 
                break
            else
                echo -e "${RED}Wrong email address. Please enter a valid email.${NC}"
            fi
        done

        echo -e "${INFO}[INFO]${YELLOW} Requesting a TLS certificate from Let's Encrypt...${NC}"

        if sudo certbot certonly --standalone --agree-tos --email "$EMAIL" -d "$DOMAIN_NAME"; then
            CERT_PATH="/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"
            KEY_PATH="/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem"

            echo -e "${SUCCESS}[SUCCESS] TLS certificate successfully obtained for ${GREEN}$DOMAIN_NAME${NC}."

            CONFIG_FILE="$SCRIPT_DIR/config.yaml"

            if [ ! -f "$CONFIG_FILE" ]; then
                echo -e "${INFO}[INFO]${YELLOW} config.yaml does not exist. Creating it...${NC}"
                cat <<EOF > "$CONFIG_FILE"
tls: false
cert_path: ""
key_path: ""
EOF
            fi

            echo -e "${INFO}[INFO]${YELLOW} Updating config.yaml with TLS settings...${NC}"
            sed -i "s|tls: false|tls: true|g" "$CONFIG_FILE"
            sed -i "s|cert_path: \"\"|cert_path: \"$CERT_PATH\"|g" "$CONFIG_FILE"
            sed -i "s|key_path: \"\"|key_path: \"$KEY_PATH\"|g" "$CONFIG_FILE"

            echo -e "${SUCCESS}[SUCCESS] TLS configuration successfully added to config.yaml.${NC}"
        else
            echo -e "${RED}[ERROR] Failed to obtain TLS certificate. Please check your sub-domain and email address.${NC}"
        fi
    else
        echo -e "${CYAN}[INFO] Skipping TLS setup.${NC}"
    fi
}

show_flask_info() {
    echo -e "\033[92mFlask Access Info\033[0m"
    echo -e '\033[92m══════════════════════════════════\033[0m'

    FLASK_PORT=$(grep -i 'port' "$SCRIPT_DIR/config.yaml" | awk '{print $2}')
    TLS_ENABLED=$(grep -i 'tls' "$SCRIPT_DIR/config.yaml" | awk '{print $2}')
    CERT_PATH=$(grep -i 'cert_path' "$SCRIPT_DIR/config.yaml" | awk '{print $2}')
    FLASK_PUBLIC_IP=$(curl -s http://checkip.amazonaws.com) 

    if ( [ "$TLS_ENABLED" == "true" ] && [ -n "$CERT_PATH" ] ); then
        SUBDOMAIN=$(echo "$CERT_PATH" | awk -F'/' '{print $(NF-1)}')  

       echo -e "\033[93m══════════════════════════════════\033[0m"
       echo -e "${LIGHT_GREEN}TLS is enabled!${NC}"
       echo -e "${CYAN}You can access your Flask app at:${NC}"
       echo -e "${LIGHT_BLUE}https://${SUBDOMAIN}:${FLASK_PORT}${NC}"
       echo -e "${CYAN}Ensure your DNS is correctly pointed to this subdomain.${NC}"
       echo -e "\033[93m══════════════════════════════════\033[0m"

    else
        echo -e "\033[93m══════════════════════════════════\033[0m"
        echo -e "${LIGHT_GREEN}Flask is running without TLS!${NC}"
        echo -e "${CYAN}You can access your Flask app at:${NC}"
        echo -e "${LIGHT_BLUE}${FLASK_PUBLIC_IP}:${FLASK_PORT}${NC}"
        echo -e "${CYAN}You can use this IP to access the app directly.${NC}"
        echo -e "\033[93m══════════════════════════════════\033[0m"
    fi

}

wireguardconf() {
    echo -e "\n${BLUE}[INFO]=== Wireguard Installation and Configuration ===${NC}\n"

    if ! command -v wg &>/dev/null; then
        echo -e "${BLUE}[INFO] Wireguard not found. Installing...${NC}"
        apt-get update -y && apt-get install -y wireguard
        if [ $? -ne 0 ]; then
            echo -e "${RED}[ERROR] Couldn't install Wireguard.${NC}"
            return 1
        fi
        echo -e "${SUCCESS}[SUCCESS] Wireguard installed successfully!${NC}"
    else
        echo -e "${INFO}[INFO] Wireguard is already installed. Skipping...${NC}"
    fi

    echo -e '\033[93m══════════════════════════════════════════════════\033[0m'

    while true; do
        echo -e "${YELLOW}Enter the ${BLUE}Wireguard ${GREEN}interface name${NC} (wg0 and so on):${NC} \c"
        read -e WG_NAME
        if [ -n "$WG_NAME" ]; then
            echo -e "${INFO}[INFO] Interface Name set to: ${GREEN}$WG_NAME${NC}"
            break
        else
            echo -e "${RED}Interface name cannot be empty. Please try again.${NC}"
        fi
    done

    local WG_CONFIG="/etc/wireguard/${WG_NAME}.conf"
    local PRIVATE_KEY
    PRIVATE_KEY=$(wg genkey)

    local SERVER_INTERFACE
    SERVER_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    [ -z "${SERVER_INTERFACE}" ] && SERVER_INTERFACE="eth0"

    while true; do
        echo -e "${YELLOW}Enter the ${BLUE}Wireguard ${GREEN}private IP address${NC} (example 176.66.66.1/24):${NC} \c"
        read -e WG_ADDRESS
        if [[ "$WG_ADDRESS" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
            echo -e "${INFO}[INFO] Private IP Address set to: ${GREEN}$WG_ADDRESS${NC}"
            break
        else
            echo -e "${RED}Wrong IP address format. Please try again.${NC}"
        fi
    done

    while true; do
        echo -e "${YELLOW}Enter the ${BLUE}Wireguard ${GREEN}listen port${NC} (example 20820):${NC} \c"
        read -e WG_PORT
        if [[ "$WG_PORT" =~ ^[0-9]+$ ]] && [ "$WG_PORT" -ge 1 ] && [ "$WG_PORT" -le 65535 ]; then
            echo -e "${INFO}[INFO] Listen Port set to: ${GREEN}$WG_PORT${NC}"
            break
        else
            echo -e "${RED}Wrong port number. Please enter a valid port between 1 and 65535.${NC}"
        fi
    done

    while true; do
        echo -e "${YELLOW}Enter the ${BLUE}MTU ${GREEN}size${NC} (example 1420):${NC} \c"
        read -e MTU
        if [[ "$MTU" =~ ^[0-9]+$ ]]; then
            echo -e "${INFO}[INFO] MTU Size set to: ${GREEN}$MTU${NC}"
            break
        else
            echo -e "${RED}Wrong MTU size. Please try again.${NC}"
        fi
    done

    echo -e '\033[93m══════════════════════════════════════════════════\033[0m'

    if [ ! -d "/etc/wireguard" ]; then
        echo -e "${INFO}[INFO] Creating /etc/wireguard directory...${NC}"
        sudo mkdir -p /etc/wireguard
    fi

    echo -e "${INFO}[INFO] Generating Wireguard config at ${WG_CONFIG}...${NC}"
    cat <<EOL > "${WG_CONFIG}"
[Interface]
Address = ${WG_ADDRESS}
ListenPort = ${WG_PORT}
PrivateKey = ${PRIVATE_KEY}
MTU = ${MTU}
DNS = ${DNS}

PostUp = iptables -I INPUT -p udp --dport ${WG_PORT} -j ACCEPT
PostUp = iptables -I FORWARD -i ${SERVER_INTERFACE} -o ${WG_NAME} -j ACCEPT
PostUp = iptables -I FORWARD -i ${WG_NAME} -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o ${SERVER_INTERFACE} -j MASQUERADE

PostDown = iptables -D INPUT -p udp --dport ${WG_PORT} -j ACCEPT
PostDown = iptables -D FORWARD -i ${SERVER_INTERFACE} -o ${WG_NAME} -j ACCEPT
PostDown = iptables -D FORWARD -i ${WG_NAME} -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ${SERVER_INTERFACE} -j MASQUERADE
EOL

    chmod 600 "${WG_CONFIG}" || { echo -e "${RED}[ERROR] Couldn't set permissions on ${WG_CONFIG}.${NC}"; return 1; }

    echo -e "${INFO}[INFO] Bringing up Wireguard interface ${WG_NAME}...${NC}"
    if ! wg-quick up "${WG_NAME}"; then
        echo -e "${RED}[ERROR] Couldn't bring up ${WG_NAME}. Check config or logs.${NC}"
        return 1
    fi

    echo -e "${INFO}[INFO] Enabling Wireguard interface ${WG_NAME}${NC}"
    if ! systemctl enable "wg-quick@${WG_NAME}"; then
        echo -e "${RED}[ERROR] Couldn't enable wg-quick@${WG_NAME} on boot.${NC}"
        return 1
    fi

    echo -e "\n${GREEN}Wireguard interface ${WG_NAME} created & activated successfully!${NC}"

    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

create_config() {
    echo -e "\033[92mFlask Setup\033[0m"
    echo -e '\033[92m══════════════════════════════════\033[0m'
    
    echo -e "${INFO}[INFO] Creating or updating Flask setup...${NC}"
    echo -e '\033[93m══════════════════════════════════\033[0m'

    while true; do
        echo -ne "${YELLOW}Enter the ${GREEN}Flask port ${YELLOW}[example: 8000, default: 5000]: ${NC}"
        read -e FLASK_PORT
        FLASK_PORT=${FLASK_PORT:-5000}
        if [[ "$FLASK_PORT" =~ ^[0-9]+$ ]] && [ "$FLASK_PORT" -ge 1 ] && [ "$FLASK_PORT" -le 65535 ]; then
            echo -e "${CYAN}[INFO] Flask Port: ${GREEN}$FLASK_PORT${NC}"
            break
        else
            echo -e "${RED}[ERROR] Invalid port. Please enter a valid number between 1 and 65535.${NC}"
        fi
    done

    echo -ne "${YELLOW}Enable ${GREEN}Flask ${YELLOW}debug mode? ${GREEN}[yes]${NC}/${RED}[no]${NC} [default: no]: ${NC}"
    read -e FLASK_DEBUG
    FLASK_DEBUG=${FLASK_DEBUG:-no}
    FLASK_DEBUG=$(echo "$FLASK_DEBUG" | grep -iq "^y" && echo "true" || echo "false")
    echo -e "\n${CYAN}[INFO] Flask Debug Mode: ${GREEN}$FLASK_DEBUG${NC}"

    while true; do
        echo -ne "${YELLOW}Enter the number of ${GREEN}Gunicorn workers ${YELLOW}[default: 2]: ${NC}"
        read -e GUNICORN_WORKERS
        GUNICORN_WORKERS=${GUNICORN_WORKERS:-2}
        if [[ "$GUNICORN_WORKERS" =~ ^[0-9]+$ ]]; then
            echo -e "\n${CYAN}[INFO] Gunicorn Workers: ${GREEN}$GUNICORN_WORKERS${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Invalid number. Please enter a valid number.${NC}"
        fi
    done

    while true; do
        echo -ne "${YELLOW}Enter the number of ${GREEN}Gunicorn threads ${YELLOW}[default: 1]: ${NC}"
        read -e GUNICORN_THREADS
        GUNICORN_THREADS=${GUNICORN_THREADS:-1}
        if [[ "$GUNICORN_THREADS" =~ ^[0-9]+$ ]]; then
            echo -e "\n${CYAN}[INFO] Gunicorn Threads: ${GREEN}$GUNICORN_THREADS${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Invalid number. Please enter a valid number.${NC}"
        fi
    done

    while true; do
        echo -ne "${YELLOW}Enter the ${GREEN}Gunicorn timeout ${YELLOW}in seconds [default: 120]: ${NC}"
        read -e GUNICORN_TIMEOUT
        GUNICORN_TIMEOUT=${GUNICORN_TIMEOUT:-120}
        if [[ "$GUNICORN_TIMEOUT" =~ ^[0-9]+$ ]]; then
            echo -e "\n${CYAN}[INFO] Gunicorn Timeout: ${GREEN}$GUNICORN_TIMEOUT${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Invalid timeout. Please enter a valid number.${NC}"
        fi
    done

    while true; do
        echo -ne "${YELLOW}Enter the ${GREEN}Gunicorn log level ${YELLOW}[default: info]: ${NC}"
        read -e GUNICORN_LOGLEVEL
        GUNICORN_LOGLEVEL=${GUNICORN_LOGLEVEL:-info}
        if [[ "$GUNICORN_LOGLEVEL" =~ ^(debug|info|warning|error|critical)$ ]]; then
            echo -e "\n${CYAN}[INFO] Gunicorn Log Level: ${GREEN}$GUNICORN_LOGLEVEL${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Invalid log level. Valid options: debug, info, warning, error, critical.${NC}"
        fi
    done

    while true; do
        echo -ne "${YELLOW}Enter the ${GREEN}Flask ${YELLOW}secret key ${NC}(used for session management): ${NC}"
        read -e FLASK_SECRET_KEY
        if [ -n "$FLASK_SECRET_KEY" ]; then
            echo -e "\n${CYAN}[INFO] Flask Secret Key: ${GREEN}$FLASK_SECRET_KEY${NC}"
            break
        else
            echo -e "\n${RED}[ERROR] Secret key cannot be empty. Please enter a valid value.${NC}"
        fi
    done

    setup_tls

    echo -e '\033[93m══════════════════════════════════\033[0m'
    echo -e "${INFO}[INFO] Creating config.yaml file...${NC}"

    cat <<EOL >"$SCRIPT_DIR/config.yaml"
flask:
  port: $FLASK_PORT
  tls: $([ "$ENABLE_TLS" = "yes" ] && echo "true" || echo "false")
  cert_path: "$CERT_PATH"
  key_path: "$KEY_PATH"
  secret_key: "$FLASK_SECRET_KEY"
  debug: $FLASK_DEBUG

gunicorn:
  workers: $GUNICORN_WORKERS
  threads: $GUNICORN_THREADS
  loglevel: "$GUNICORN_LOGLEVEL"
  timeout: $GUNICORN_TIMEOUT
  accesslog: "$GUNICORN_ACCESS_LOG"
  errorlog: "$GUNICORN_ERROR_LOG"

wireguard:
  config_dir: "/etc/wireguard"
EOL

    if [[ $? -eq 0 ]]; then
        echo -e "${LIGHT_GREEN}config.yaml created successfully.${NC}"
    else
        echo -e "${RED}[ERROR] Couldn't create config.yaml. Please check for errors.${NC}"
    fi

    echo -e "${CYAN}Restarting wireguard-panel service to apply new configuration...${NC}"
    sudo systemctl restart wireguard-panel.service && echo -e "${LIGHT_GREEN}✔ wireguard-panel restarted successfully.${NC}" || echo -e "${LIGHT_RED}✘ Failed to restart wireguard-panel service.${NC}"

    echo -e "${CYAN}Press Enter to continue...${NC}" && read

}

wireguard_panel() {
    echo -e "\033[92mWireguard Service env\033[0m"
    echo -e '\033[92m══════════════════════════════════\033[0m'
    echo -e "${INFO}[INFO]Wireguard Service${NC}"
    echo -e '\033[93m══════════════════════════════════\033[0m'

    APP_FILE="$SCRIPT_DIR/app.py"
    VENV_DIR="$SCRIPT_DIR/venv"
    SERVICE_FILE="/etc/systemd/system/wireguard-panel.service"

    if [ ! -f "$APP_FILE" ]; then
        echo -e "${RED}[Error] $APP_FILE not found. make sure that Wireguard panel is in the correct directory.${NC}"
        echo -e "${CYAN}Press Enter to continue...${NC}" && read
        return 1
    fi

    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}[Error] Virtual env not found in $VENV_DIR. install it first from the script menu.${NC}"
        echo -e "${CYAN}Press Enter to continue...${NC}" && read
        return 1
    fi

    sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Wireguard Panel
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$SCRIPT_DIR
ExecStart=$VENV_DIR/bin/python3 $APP_FILE
Restart=always
Environment=PATH=$VENV_DIR/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=LANG=en_US.UTF-8
Environment=LC_ALL=en_US.UTF-8

[Install]
WantedBy=multi-user.target
EOL

    sudo chmod 644 "$SERVICE_FILE"
    sudo systemctl daemon-reload
    sudo systemctl enable wireguard-panel.service
    sudo systemctl restart wireguard-panel.service

    if [ "$(sudo systemctl is-active wireguard-panel.service)" = "active" ]; then
        echo -e "${LIGHT_GREEN}[Success] Wireguard Panel service is running successfully.${NC}"
    else
        echo -e "${RED}[Error] Couldn't start the Wireguard Panel service.${NC}"
        echo -e "${CYAN}Press Enter to continue...${NC}" && read
        return 1
    fi

    show_flask_info

    echo -e "${CYAN}Press Enter to continue...${NC}" && read
}

automatic_install() {
    clear
    echo -e "${CYAN}=====================================================${NC}"
    echo -e "${CYAN}  Starting Automatic Wireguard Panel Installation  ${NC}"
    echo -e "${CYAN}=====================================================${NC}"

    echo -e "\n${BLUE}Step 1: Installing Requirements...${NC}"
    install_requirements
    if [ $? -ne 0 ]; then echo -e "${ERROR}Failed to install requirements. Aborting installation.${NC}"; exit 1; fi

    echo -e "\n${BLUE}Step 2: Setting up Virtual Environment...${NC}"
    setup_virtualenv
    if [ $? -ne 0 ]; then echo -e "${ERROR}Failed to set up virtual environment. Aborting installation.${NC}"; exit 1; fi

    echo -e "\n${BLUE}Step 3: Creating Flask & Gunicorn Configuration...${NC}"
    create_config
    if [ ! -f "$SCRIPT_DIR/config.yaml" ]; then
        echo -e "${ERROR}Flask/Gunicorn configuration (config.yaml) was not created. Aborting installation.${NC}"
        exit 1
    fi

    echo -e "\n${BLUE}Step 4: Creating Wireguard Interface...${NC}"
    wireguardconf
    if [ $? -ne 0 ]; then echo -e "${ERROR}Failed to configure Wireguard interface. Aborting installation.${NC}"; exit 1; fi

    echo -e "\n${BLUE}Step 5: Setting up Permissions...${NC}"
    setup_permissions
    if [ $? -ne 0 ]; then echo -e "${ERROR}Failed to set up permissions. Aborting installation.${NC}"; exit 1; fi
    
    echo -e "\n${BLUE}Step 6: Setting up Wireguard Panel Service...${NC}"
    wireguard_panel
    if [ $? -ne 0 ]; then 
        echo -e "${ERROR}Failed to set up or start Wireguard Panel service. Please check logs.${NC}"
        echo -e "${YELLOW}You might need to run 'sudo systemctl status wireguard-panel.service' and 'journalctl -u wireguard-panel.service' to diagnose.${NC}"
    fi

    echo -e "\n${SUCCESS}======================================================${NC}"
    echo -e "${SUCCESS}  Wireguard Panel Installation Process Completed!  ${NC}"
    echo -e "${SUCCESS}======================================================${NC}\n"
    
    show_flask_info

    echo -e "\n${CYAN}The setup script has finished. Please check for any error messages above.${NC}"
    echo -e "${CYAN}If the service is running, you should be able to access the panel using the information displayed.${NC}"
}

automatic_install

exit 0
