#!/bin/bash

# wgd.sh - Copyright(C) 2025 iPmartNetwork [https://github.com/iPmartNetwork]
## devloper : Ali Hassanzadeh

app_name="dashboard.py"
app_official_name="WGDashboard"
PID_FILE=./gunicorn.pid
environment=$(if [[ $ENVIRONMENT ]]; then echo $ENVIRONMENT; else echo 'develop'; fi)
if [[ $CONFIGURATION_PATH ]]; then
  cb_work_dir=$CONFIGURATION_PATH/letsencrypt/work-dir
  cb_config_dir=$CONFIGURATION_PATH/letsencrypt/config-dir
else
  cb_work_dir=/etc/letsencrypt
  cb_config_dir=/var/lib/letsencrypt
fi

dashes='------------------------------------------------------------'
equals='============================================================'
log_file="wgd.log"

log() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $message" | tee -a "$log_file"
}

check_dependencies() {
  log "INFO" "Checking required dependencies..."
  dependencies=("python3" "pip" "gunicorn" "certbot")
  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      log "ERROR" "Dependency '$dep' is not installed. Please install it and try again."
      exit 1
    fi
  done
  log "INFO" "All dependencies are installed."
}

safe_execute() {
  local command="$1"
  log "INFO" "Executing: $command"
  if ! eval "$command"; then
    log "ERROR" "Command failed: $command"
    exit 1
  fi
}

help() {
  GREEN='\033[92m'
  YELLOW='\033[93m'
  BLUE='\033[96m'
  NC='\033[0m' 
  display_logo2
  printf "${YELLOW}=================================================================================\n"
  printf "${YELLOW}+     ${BLUE}<Wireguard Panel> by iPmartNetwork ${BLUE}https://github.com/iPmartNetwork        ${YELLOW}+\n"
  printf "${YELLOW}=================================================================================${NC}\n"
  printf "${YELLOW}| Usage: ${GREEN}./wgd.sh <option>${NC}                                                      ${YELLOW}|\n"
  printf "${YELLOW}|                                                                               ${YELLOW}|\n"
  printf "${YELLOW}| Available options:                                                            ${YELLOW}|\n"
  printf "${YELLOW}|    ${GREEN}start${NC}: To start Wireguard Panel.                                           ${YELLOW}|\n"
  printf "${YELLOW}|    ${GREEN}stop${NC}: To stop Wireguard Panel.                                             ${YELLOW}|\n"
  printf "${YELLOW}|    ${GREEN}debug${NC}: To start Wireguard Panel in debug mode (i.e., run in foreground).   ${YELLOW}|\n"
  printf "${YELLOW}|    ${GREEN}install${NC}: To install Wireguard Panel                                        ${YELLOW}|\n"
  printf "${YELLOW}=================================================================================${NC}\n"
}
_check_and_set_venv(){
    # This function will not be using in v3.0
    # deb/ubuntu users: might need a 'apt install python3.8-venv'
    # set up the local environment
    APP_ROOT=`pwd`
    VIRTUAL_ENV="${APP_ROOT%/*}/venv"
    if [ ! -d $VIRTUAL_ENV ]; then
        python3 -m venv $VIRTUAL_ENV
    fi
    . ${VIRTUAL_ENV}/bin/activate
}
function display_logo2() {
echo -e "\033[1;92m$logo2\033[0m"
}
# iPmartNetwork art
logo2=$(cat << "EOF"

iPmartNetwork.com
   
EOF
)
function display_logo() {
echo -e "\033[1;96m$logo\033[0m"
}
# iPmartNetwork art
logo=$(cat << "EOF"

iPmartNetwork.com

EOF
)
install_wgd() {
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[93m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
LIGHT_GREEN='\033[1;32m'
BOLD='\033[1m'
RESET='\033[0m'

    print_box() {
        local text="$1"
        local color="$2"
        local width=$((${#text} + 2))
        local dashes=$(printf "─%.0s" $(seq 1 $width))

        printf "${color}╭${dashes}╮${RESET}\n"
        printf "${color}│ ${text} │${RESET}\n"
        printf "${color}╰${dashes}╯${RESET}\n"
    }

    display_logo

    version_pass=$(python3 -c 'import sys; print("1") if (sys.version_info.major == 3 and sys.version_info.minor >= 7) else print("0");')
    if [ $version_pass == "0" ]; then
        print_box "Wireguard Panel requires Python 3.7 or above" "${RED}"
        exit 1
    fi

    if [ ! -d "db" ]; then
        mkdir "db"
    fi
    if [ ! -d "log" ]; then
        mkdir "log"
    fi

    print_box "Upgrading pip, Please Wait!" "${BLUE}"
    python3 -m pip install -U pip > /dev/null 2>&1

    print_box "Installing latest Python dependencies" "${CYAN}"
    python3 -m pip install -U -r requirements.txt > /dev/null 2>&1

    print_box "Wireguard Panel installed successfully!" "${LIGHT_GREEN}"
    print_box "Enter ./wgd.sh start to start the dashboard!" "${YELLOW}"
}

check_wgd_status(){
  if test -f "$PID_FILE"; then
    if ps aux | grep -v grep | grep $(cat ./gunicorn.pid)  > /dev/null; then
    return 0
    else
      return 1
    fi
  else
    if ps aux | grep -v grep | grep '[p]ython3 '$app_name > /dev/null; then
      return 0
    else
      return 1
    fi
  fi
}

certbot_create_ssl () {
  certbot certonly --config ./certbot.ini --email "$EMAIL" --work-dir $cb_work_dir --config-dir $cb_config_dir --domain "$SERVERURL"
}

certbot_renew_ssl () {
  certbot renew --work-dir $cb_work_dir --config-dir $cb_config_dir
}

print_box() {
  local text="$1"
  local color="$2"
  local width=$((${#text} + 4))
  local dashes=$(printf "%-${width}s" "-" | tr ' ' "~")
  
  printf "${color}╭${dashes}╮${NC}\n"
  printf "${color}│  ${text}  │${NC}\n"
  printf "${color}╰${dashes}╯${NC}\n"
}

gunicorn_start() {
  GREEN='\033[92m'
  YELLOW='\033[93m'
  BLUE='\033[96m'
  NC='\033[0m'

  log "INFO" "Starting Wireguard Panel with Gunicorn in the background..."
  mkdir -p log
  local timestamp
  timestamp=$(date '+%Y%m%d%H%M%S')

  if [[ $USER == root ]]; then
    export PATH=$PATH:/usr/local/bin:$HOME/.local/bin
  fi

  safe_execute "gunicorn --access-logfile log/access_${timestamp}.log \
    --error-logfile log/error_${timestamp}.log 'dashboard:run_dashboard()'"

  log "INFO" "Log files are located in the 'log/' directory."
}

gunicorn_stop () {
  kill $(cat ./gunicorn.pid)
}

check_python_dependencies() {
  log "INFO" "Checking and installing required Python dependencies..."
  if [ -f "requirements.txt" ]; then
    if ! python3 -m pip install -U -r requirements.txt; then
      log "ERROR" "Failed to install Python dependencies. Please check requirements.txt and ensure all required modules are listed."
      exit 1
    fi
  else
    log "ERROR" "requirements.txt not found. Cannot verify Python dependencies."
    exit 1
  fi
}

start_wgd () {
    check_python_dependencies
    gunicorn_start
}

stop_wgd() {
  if test -f "$PID_FILE"; then
    gunicorn_stop
  else
    kill "$(ps aux | grep "[p]ython3 $app_name" | awk '{print $2}')"
  fi
}

start_wgd_debug() {

    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
	GREEN='\033[92m'
    RESET='\033[0m'

print_box() {
  local text="$1"
  local color="$2"
  local width=$((${#text} + 4))
  local dashes=$(printf "%-${width}s" "-" | tr ' ' "-")
  
  printf "${color}╔${dashes}╗${RESET}\n"
  printf "${color}║  ${text}  ║${RESET}\n"
  printf "${color}╚${dashes}╝${RESET}\n"
}

    dashes=$(printf "%-${logo_width}s" "─" | tr ' ' "─")

    printf "%s\n" "$dashes"
    print_box "Wireguard Panel in the foreground." "${GREEN}"
    python3 "$app_name"
    printf "%s\n" "$dashes"
}

update_wgd() {
  log "INFO" "Checking for updates..."
  new_ver=$(python3 -c "import json; import urllib.request; data = urllib.request.urlopen('https://api.github.com/repos/iPmartNetwork/WireGuard-Dashboard/releases/latest').read(); output = json.loads(data); print(output['tag_name'])")
  log "INFO" "Latest version available: $new_ver"
  printf "| Are you sure you want to update to %s? (Y/N): " "$new_ver"
  read -r up
  if [ "$up" = "Y" ]; then
    log "INFO" "Updating to version $new_ver..."
    if check_wgd_status; then
      stop_wgd
    fi
    mv wgd.sh wgd.sh.old
    safe_execute "git stash"
    safe_execute "git pull https://github.com/iPmartNetwork/iPWG.git $new_ver --force"
    safe_execute "python3 -m pip install -U pip"
    safe_execute "python3 -m pip install -U -r requirements.txt"
    log "INFO" "Update completed successfully!"
    rm wgd.sh.old
  else
    log "INFO" "Update canceled by the user."
  fi
}

YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
GREEN='\033[92m'
NC='\033[0m'

print_box() {
  local text="$1"
  local color="$2"
  local width=$((${#text} + 4))
  local dashes=$(printf "%-${width}s" "-" | tr ' ' "-")
  
  printf "${color}╔${dashes}╗${NC}\n"
  printf "${color}║  ${text}  ║${NC}\n"
  printf "${color}╚${dashes}╝${NC}\n"
}

if [ "$#" != 1 ]; then
  help
else
  if [ "$1" = "start" ]; then
    if check_wgd_status; then
      printf "%s\n" "$dashes"
      printf "${GREEN}| Wireguard Panel is already running.                          ${NC}|\n"
      printf "%s\n" "$dashes"
    else
      printf "%s\n" "$dashes"
      print_box "Starting Wireguard Panel with Gunicorn in the background." "$BLUE"
      start_wgd
    fi
  elif [ "$1" = "stop" ]; then
    if check_wgd_status; then
      printf "%s\n" "$dashes"
      stop_wgd
      print_box "Wireguard Panel is stopped." "$GREEN"
      printf "%s\n" "$dashes"
    else
      printf "%s\n" "$dashes"
      print_box "Wireguard Panel is stopped." "$GREEN"
      printf "%s\n" "$dashes"
      printf "${GREEN}| Wireguard Panel is not running.                              ${NC}|\n"
      printf "%s\n" "$dashes"
    fi
  elif [ "$1" = "update" ]; then
    update_wgd
  elif [ "$1" = "install" ]; then
    printf "%s\n" "$dashes"
    install_wgd
    printf "%s\n" "$dashes"
  elif [ "$1" = "restart" ]; then
    if check_wgd_status; then
      printf "%s\n" "$dashes"
      stop_wgd
      print_box "Wireguard Panel is stopped." "$GREEN"                   
      sleep 4
      start_wgd
    else
      printf "%s\n" "$dashes"
      print_box "Wireguard Panel is not running. Starting it now." "$GREEN"
      start_wgd
    fi
  elif [ "$1" = "debug" ]; then
    if check_wgd_status; then
      printf "%s\n" "$dashes"
      printf "${GREEN}| Wireguard Panel is already running.                          ${NC}|\n"
    else
      printf "%s\n" "$dashes"
      print_box "Starting Wireguard Panel with Gunicorn in the background." "$BLUE"
      start_wgd_debug
    fi
  else
    help
  fi
fi
