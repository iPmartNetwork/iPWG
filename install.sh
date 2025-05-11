#!/bin/bash

LIGHT_RED="\033[1;31m"
LIGHT_GREEN="\033[1;32m"
LIGHT_YELLOW="\033[1;33m"
LIGHT_BLUE="\033[1;34m"
CYAN="\033[0;36m"
NC="\033[0m"  # No Color

# New constants for better readability
REPO_URL="https://github.com/iPmartNetwork/iPWG.git"
SCRIPT_INSTALL_DIR="/usr/local/bin/Wireguard-panel" # Main installation directory for the panel
TMP_DIR="/tmp/ipwg-panel-update" # Temporary directory for updates

# Function to print messages
print_message() {
    COLOR=$1
    MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}${NC}"
}

prompt_action() {
    print_message "$CYAN" "Select an action:"
    print_message "$CYAN" "════════════════════════════════════════"
    print_message "$LIGHT_YELLOW" "1) ${LIGHT_GREEN}Update Panel${NC}"
    print_message "$LIGHT_YELLOW" "2) ${NC}Install/Reinstall Panel${NC}"
    print_message "$CYAN" "════════════════════════════════════════"
    read -p "Enter your choice (1 or 2): " ACTION_CHOICE
}

update_files() {
    print_message "$CYAN" "🚀 Starting WireGuard Panel update..."

    if [ -d "$TMP_DIR" ]; then
        print_message "$LIGHT_YELLOW" "🧹 Removing existing temporary directory..."
        if sudo rm -rf "$TMP_DIR"; then
            print_message "$LIGHT_GREEN" "✔ Temporary directory removed."
        else
            print_message "$LIGHT_RED" "✘ Error: Failed to remove temporary directory $TMP_DIR."
            return 1
        fi
    fi

    print_message "$LIGHT_BLUE" "📥 Cloning repository from $REPO_URL..."
    if sudo git clone --depth 1 "$REPO_URL" "$TMP_DIR"; then
        print_message "$LIGHT_GREEN" "✔ Repository cloned successfully."
    else
        print_message "$LIGHT_RED" "✘ Error: Failed to clone repository."
        return 1
    fi

    print_message "$CYAN" "🔄 Replacing panel files..."

    # Remove old Telegram bot files (if they exist from a previous structure)
    if [ -f "$SCRIPT_INSTALL_DIR/src/telegram/robot.py" ]; then
        if sudo rm "$SCRIPT_INSTALL_DIR/src/telegram/robot.py"; then print_message "$LIGHT_GREEN" "✔ Removed old: telegram/robot.py"; else print_message "$LIGHT_RED" "✘ Failed to remove old: telegram/robot.py"; fi
    fi
    if [ -f "$SCRIPT_INSTALL_DIR/src/telegram/robot-fa.py" ]; then
        if sudo rm "$SCRIPT_INSTALL_DIR/src/telegram/robot-fa.py"; then print_message "$LIGHT_GREEN" "✔ Removed old: telegram/robot-fa.py"; else print_message "$LIGHT_RED" "✘ Failed to remove old: telegram/robot-fa.py"; fi
    fi

    # Update app.py
    if [ -f "$TMP_DIR/src/app.py" ]; then
        if sudo mv "$TMP_DIR/src/app.py" "$SCRIPT_INSTALL_DIR/src/"; then print_message "$LIGHT_GREEN" "✔ Updated: src/app.py"; else print_message "$LIGHT_RED" "✘ Failed to update: src/app.py"; fi
    else
        print_message "$LIGHT_RED" "❗ Warning: src/app.py not found in the new version."
    fi

    # Update static directory (excluding images)
    if [ -d "$TMP_DIR/src/static" ]; then
        print_message "$LIGHT_BLUE" "Updating src/static directory (excluding images)..."
        sudo mkdir -p "$SCRIPT_INSTALL_DIR/src/static"
        for item in "$TMP_DIR/src/static/"*; do
            local base_item=$(basename "$item")
            if [ "$base_item" != "images" ]; then
                if sudo cp -r "$item" "$SCRIPT_INSTALL_DIR/src/static/"; then print_message "$LIGHT_GREEN" "  ✔ Updated: src/static/$base_item"; else print_message "$LIGHT_RED" "  ✘ Failed to update: src/static/$base_item"; fi
            fi
        done
    else
        print_message "$LIGHT_RED" "❗ Warning: src/static directory not found in the new version."
    fi

    # Update templates directory
    if [ -d "$TMP_DIR/src/templates" ]; then
        if sudo rm -rf "$SCRIPT_INSTALL_DIR/src/templates" && sudo mv "$TMP_DIR/src/templates" "$SCRIPT_INSTALL_DIR/src/"; then print_message "$LIGHT_GREEN" "✔ Updated: src/templates"; else print_message "$LIGHT_RED" "✘ Failed to update: src/templates"; fi
    else
        print_message "$LIGHT_RED" "❗ Warning: src/templates directory not found in the new version."
    fi
    
    # Update Telegram bot files
    if [ -f "$TMP_DIR/src/telegram/robot.py" ]; then
        if sudo mv "$TMP_DIR/src/telegram/robot.py" "$SCRIPT_INSTALL_DIR/src/telegram/"; then print_message "$LIGHT_GREEN" "✔ Updated: src/telegram/robot.py"; else print_message "$LIGHT_RED" "✘ Failed to update: src/telegram/robot.py"; fi
    else
        print_message "$LIGHT_YELLOW" "ℹ️ Note: src/telegram/robot.py not found in the new version (might be intentional)."
    fi
    if [ -f "$TMP_DIR/src/telegram/robot-fa.py" ]; then
        if sudo mv "$TMP_DIR/src/telegram/robot-fa.py" "$SCRIPT_INSTALL_DIR/src/telegram/"; then print_message "$LIGHT_GREEN" "✔ Updated: src/telegram/robot-fa.py"; else print_message "$LIGHT_RED" "✘ Failed to update: src/telegram/robot-fa.py"; fi
    else
        print_message "$LIGHT_YELLOW" "ℹ️ Note: src/telegram/robot-fa.py not found in the new version (might be intentional)."
    fi

    # Update telegram/static directory (excluding images)
    if [ -d "$TMP_DIR/src/telegram/static" ]; then
        print_message "$LIGHT_BLUE" "Updating src/telegram/static directory (excluding images)..."
        sudo mkdir -p "$SCRIPT_INSTALL_DIR/src/telegram/static"
        for item in "$TMP_DIR/src/telegram/static/"*; do
            local base_item=$(basename "$item")
            if [ "$base_item" != "images" ]; then
                if sudo cp -r "$item" "$SCRIPT_INSTALL_DIR/src/telegram/static/"; then print_message "$LIGHT_GREEN" "  ✔ Updated: src/telegram/static/$base_item"; else print_message "$LIGHT_RED" "  ✘ Failed to update: src/telegram/static/$base_item"; fi
            fi
        done
    else
        print_message "$LIGHT_RED" "❗ Warning: src/telegram/static directory not found in the new version."
    fi
    
    # Update setup.sh
    if [ -f "$TMP_DIR/src/setup.sh" ]; then
        if sudo mv "$TMP_DIR/src/setup.sh" "$SCRIPT_INSTALL_DIR/src/"; then
            print_message "$LIGHT_GREEN" "✔ Updated: src/setup.sh"
            if sudo chmod +x "$SCRIPT_INSTALL_DIR/src/setup.sh"; then print_message "$LIGHT_GREEN" "✔ Made src/setup.sh executable."; else print_message "$LIGHT_RED" "✘ Failed to make src/setup.sh executable."; fi
        else
            print_message "$LIGHT_RED" "✘ Failed to update: src/setup.sh"
        fi
    else
        print_message "$LIGHT_RED" "❗ Warning: src/setup.sh not found in the new version."
    fi

    print_message "$CYAN" "🧹 Cleaning up temporary files..."
    if sudo rm -rf "$TMP_DIR"; then print_message "$LIGHT_GREEN" "✔ Temporary files removed."; else print_message "$LIGHT_RED" "✘ Error: Failed to remove temporary files."; fi

    read -p "$(echo -e "${CYAN}Press Enter to run the updated setup.sh script...${NC}")"
    print_message "$CYAN" "⚙️ Executing setup.sh..."
    cd "$SCRIPT_INSTALL_DIR/src" || { print_message "$LIGHT_RED" "✘ Error: Failed to navigate to $SCRIPT_INSTALL_DIR/src."; return 1; }
    if sudo ./setup.sh; then
        print_message "$LIGHT_GREEN" "✔ setup.sh executed successfully."
    else
        print_message "$LIGHT_RED" "✘ Error: setup.sh execution failed. Please check the script output."
        return 1
    fi

    print_message "$LIGHT_GREEN" "✅ Update completed successfully!"
}

uninstall_panel() {
    # SCRIPT_DIR is not defined here, assuming it's the location of Wireguard-panel if this script is inside it.
    # For a global uninstaller, PANEL_DIR is more appropriate.
    local current_panel_dir="$SCRIPT_INSTALL_DIR" # Use the global constant

    print_message "$LIGHT_YELLOW" "Are you sure you want to uninstall the WireGuard Panel? This will remove panel files and potentially WireGuard configurations."
    read -p "Type 'yes' to confirm: " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        print_message "$CYAN" "ℹ️ Uninstallation aborted by user."
        return
    fi

    local BACKUP_DIR="/etc/wireguard_panel_backups/uninstall_$(date +%Y%m%d_%H%M%S)"
    local WIREGUARD_CONFIG_DIR="/etc/wireguard"
    local SYSTEMD_PANEL_SERVICE="/etc/systemd/system/wireguard-panel.service"
    local SYSTEMD_TELEGRAM_EN_SERVICE="/etc/systemd/system/telegram-bot-en.service"
    local SYSTEMD_TELEGRAM_FA_SERVICE="/etc/systemd/system/telegram-bot-fa.service"
    local WIRE_CLI_SCRIPT="/usr/local/bin/wire"

    print_message "$LIGHT_BLUE" "🛡️ Backing up data to $BACKUP_DIR..."
    if sudo mkdir -p "$BACKUP_DIR"; then
        print_message "$LIGHT_GREEN" "✔ Backup directory created."
    else
        print_message "$LIGHT_RED" "✘ Error: Could not create backup directory $BACKUP_DIR. Aborting."
        return 1
    fi

    # Backup panel database and other critical panel files if they exist
    if [ -d "$current_panel_dir/db" ]; then
        if sudo cp -r "$current_panel_dir/db" "$BACKUP_DIR/panel_db"; then print_message "$LIGHT_GREEN" "  ✔ Panel database backed up."; else print_message "$LIGHT_YELLOW" "  ⚠️ Couldn't back up panel database."; fi
    else
        print_message "$LIGHT_YELLOW" "  ℹ️ No panel database found at $current_panel_dir/db to back up."
    fi
    if [ -d "$current_panel_dir/backups" ]; then # Panel's own backup folder
        if sudo cp -r "$current_panel_dir/backups" "$BACKUP_DIR/panel_internal_backups"; then print_message "$LIGHT_GREEN" "  ✔ Panel internal backups directory saved."; else print_message "$LIGHT_YELLOW" "  ⚠️ Couldn't back up panel internal backups directory."; fi
    fi
     if [ -f "$current_panel_dir/src/short_links.json" ]; then
        if sudo cp "$current_panel_dir/src/short_links.json" "$BACKUP_DIR/short_links.json"; then print_message "$LIGHT_GREEN" "  ✔ short_links.json backed up."; else print_message "$LIGHT_YELLOW" "  ⚠️ Couldn't back up short_links.json."; fi
    fi


    print_message "$LIGHT_BLUE" "🛡️ Backing up WireGuard configurations from $WIREGUARD_CONFIG_DIR..."
    if [ -d "$WIREGUARD_CONFIG_DIR" ]; then
        if sudo cp -r "$WIREGUARD_CONFIG_DIR" "$BACKUP_DIR/wireguard_configs"; then print_message "$LIGHT_GREEN" "✔ WireGuard configurations backed up."; else print_message "$LIGHT_RED" "✘ Error: Couldn't back up WireGuard configurations."; fi
    else
        print_message "$LIGHT_YELLOW" "ℹ️ No WireGuard configurations found at $WIREGUARD_CONFIG_DIR to back up."
    fi

    print_message "$LIGHT_YELLOW" "🚦 Stopping and disabling services..."
    # Stop/disable Telegram bot services
    if systemctl list-units --type=service --all | grep -q "telegram-bot-en.service"; then
        print_message "$LIGHT_BLUE" "  Stopping telegram-bot-en.service..."
        sudo systemctl stop telegram-bot-en.service
        sudo systemctl disable telegram-bot-en.service
        if sudo rm -f "$SYSTEMD_TELEGRAM_EN_SERVICE"; then print_message "$LIGHT_GREEN" "  ✔ Removed telegram-bot-en.service file."; else print_message "$LIGHT_RED" "  ✘ Failed to remove telegram-bot-en.service file."; fi
    else
        print_message "$LIGHT_YELLOW" "  ℹ️ English Telegram bot service not found or already removed."
    fi
    if systemctl list-units --type=service --all | grep -q "telegram-bot-fa.service"; then
        print_message "$LIGHT_BLUE" "  Stopping telegram-bot-fa.service..."
        sudo systemctl stop telegram-bot-fa.service
        sudo systemctl disable telegram-bot-fa.service
        if sudo rm -f "$SYSTEMD_TELEGRAM_FA_SERVICE"; then print_message "$LIGHT_GREEN" "  ✔ Removed telegram-bot-fa.service file."; else print_message "$LIGHT_RED" "  ✘ Failed to remove telegram-bot-fa.service file."; fi
    else
        print_message "$LIGHT_YELLOW" "  ℹ️ Farsi Telegram bot service not found or already removed."
    fi
    # Stop/disable WireGuard Panel service
    if [ -f "$SYSTEMD_PANEL_SERVICE" ]; then
        print_message "$LIGHT_BLUE" "  Stopping wireguard-panel.service..."
        sudo systemctl stop wireguard-panel.service
        sudo systemctl disable wireguard-panel.service
        if sudo rm -f "$SYSTEMD_PANEL_SERVICE"; then print_message "$LIGHT_GREEN" "  ✔ Removed wireguard-panel.service file."; else print_message "$LIGHT_RED" "  ✘ Failed to remove wireguard-panel.service file."; fi
    else
        print_message "$LIGHT_YELLOW" "  ℹ️ WireGuard Panel service not found or already removed."
    fi
    sudo systemctl daemon-reload

    # Option to keep WireGuard interfaces and /etc/wireguard
    read -p "$(echo -e "${LIGHT_YELLOW}Do you want to remove WireGuard configurations from $WIREGUARD_CONFIG_DIR and bring down interfaces? (This is destructive) [yes/${LIGHT_RED}NO${NC}]: ${NC}")" REMOVE_WG_CONFIGS
    if [[ "$REMOVE_WG_CONFIGS" == "yes" ]]; then
        print_message "$LIGHT_RED" "🔥 Removing WireGuard configurations and stopping interfaces..."
        if ls /etc/wireguard/*.conf >/dev/null 2>&1; then
            for iface_file in /etc/wireguard/*.conf; do
                local iface=$(basename "$iface_file" .conf)
                print_message "$LIGHT_BLUE" "  Bringing down interface $iface..."
                if sudo wg-quick down "$iface"; then print_message "$LIGHT_GREEN" "    ✔ Interface $iface brought down."; else print_message "$LIGHT_YELLOW" "    ⚠️ Couldn't bring down interface $iface (maybe not up)."; fi
            done
        else
            print_message "$LIGHT_YELLOW" "  ℹ️ No WireGuard interfaces found to bring down."
        fi
        if sudo rm -rf "$WIREGUARD_CONFIG_DIR"; then print_message "$LIGHT_GREEN" "  ✔ Removed WireGuard directory: $WIREGUARD_CONFIG_DIR."; else print_message "$LIGHT_RED" "  ✘ Error: Failed to remove $WIREGUARD_CONFIG_DIR."; fi
    else
        print_message "$CYAN" "ℹ️ WireGuard configurations and interfaces in $WIREGUARD_CONFIG_DIR will be kept."
    fi

    print_message "$LIGHT_YELLOW" "🗑️ Deleting WireGuard Panel files..."
    if [ -d "$current_panel_dir" ]; then
        if sudo rm -rf "$current_panel_dir"; then print_message "$LIGHT_GREEN" "✔ Removed panel directory: $current_panel_dir."; else print_message "$LIGHT_RED" "✘ Error: Failed to remove panel directory $current_panel_dir."; fi
    else
        print_message "$LIGHT_YELLOW" "ℹ️ Panel directory $current_panel_dir not found."
    fi

    if [ -f "$WIRE_CLI_SCRIPT" ]; then
        if sudo rm -f "$WIRE_CLI_SCRIPT"; then print_message "$LIGHT_GREEN" "✔ Removed 'wire' CLI script: $WIRE_CLI_SCRIPT."; else print_message "$LIGHT_RED" "✘ Error: Failed to remove 'wire' CLI script $WIRE_CLI_SCRIPT."; fi
    else
        print_message "$LIGHT_YELLOW" "ℹ️ 'wire' CLI script $WIRE_CLI_SCRIPT not found."
    fi

    print_message "$LIGHT_BLUE" "🧹 Performing system cleanup (apt autoremove, autoclean)..."
    if sudo apt autoremove -y && sudo apt autoclean -y; then print_message "$LIGHT_GREEN" "✔ System cleanup successful."; else print_message "$LIGHT_YELLOW" "⚠️ System cleanup encountered issues."; fi

    print_message "$LIGHT_GREEN" "✅ Uninstallation Complete! Backups (if any) are saved to: $BACKUP_DIR"
}

reinstall_panel() {
    print_message "$CYAN" "🔄 Reinstalling WireGuard Panel..."
    uninstall_panel # This will ask for confirmation

    # Check if uninstallation was aborted
    # This is a bit tricky as uninstall_panel doesn't return a clear status for abortion vs. completion.
    # Assuming if SCRIPT_INSTALL_DIR still exists, uninstallation might have been partial or aborted before dir removal.
    # A more robust way would be for uninstall_panel to set a flag or return a specific code.
    # For now, we proceed, and git clone will fail if the directory is not empty and not a git repo.

    print_message "$LIGHT_BLUE" "📥 Cloning WireGuard Panel repository to $SCRIPT_INSTALL_DIR..."
    # Ensure parent directory exists
    sudo mkdir -p "$(dirname "$SCRIPT_INSTALL_DIR")"
    if sudo git clone --depth 1 "$REPO_URL" "$SCRIPT_INSTALL_DIR"; then
        print_message "$LIGHT_GREEN" "✔ Repository cloned successfully."
    else
        print_message "$LIGHT_RED" "✘ Error: Failed to clone repository into $SCRIPT_INSTALL_DIR. Reinstallation aborted."
        return 1
    fi

    local setup_script_path="$SCRIPT_INSTALL_DIR/src/setup.sh"
    if [ -f "$setup_script_path" ]; then
        print_message "$LIGHT_BLUE" "⚙️ Making setup.sh executable..."
        if sudo chmod +x "$setup_script_path"; then print_message "$LIGHT_GREEN" "✔ setup.sh is now executable."; else print_message "$LIGHT_RED" "✘ Error: Failed to make setup.sh executable."; return 1; fi
    else
        print_message "$LIGHT_RED" "✘ Error: setup.sh not found at $setup_script_path. Reinstallation cannot proceed."
        return 1
    fi

    print_message "$CYAN" "⚙️ Running setup.sh..."
    cd "$SCRIPT_INSTALL_DIR/src" || { print_message "$LIGHT_RED" "✘ Error: Failed to navigate to $SCRIPT_INSTALL_DIR/src."; return 1; }
    if sudo ./setup.sh; then
        print_message "$LIGHT_GREEN" "✔ setup.sh executed successfully."
    else
        print_message "$LIGHT_RED" "✘ Error: setup.sh execution failed. Please check the script output."
        return 1
    fi
    print_message "$LIGHT_GREEN" "✅ Reinstallation completed successfully!"
}

create_wire_cli_script() {
    local wire_script_path="/usr/local/bin/wire"
    print_message "$CYAN" "⚙️ Creating/Updating 'wire' CLI helper script at $wire_script_path..."

    # Create the script content
    local script_content="#!/bin/bash
# Helper script to manage WireGuard Panel
# Navigates to the panel's source directory and runs setup.sh

PANEL_SRC_DIR=\"$SCRIPT_INSTALL_DIR/src\"

if [ ! -d \"\$PANEL_SRC_DIR\" ]; then
    echo -e \"\\033[1;31m✘ Error: WireGuard Panel source directory not found at \$PANEL_SRC_DIR\\033[0m\"
    echo -e \"\\033[1;33mPlease ensure the panel is installed correctly or run the download/install script again.\\033[0m\"
    exit 1
fi

if [ ! -f \"\$PANEL_SRC_DIR/setup.sh\" ]; then
    echo -e \"\\033[1;31m✘ Error: setup.sh not found in \$PANEL_SRC_DIR\\033[0m\"
    exit 1
fi

cd \"\$PANEL_SRC_DIR\" || { echo -e \"\\033[1;31m✘ Error: Could not navigate to \$PANEL_SRC_DIR\\033[0m\"; exit 1; }

# Ensure setup.sh is executable (should be set during install/update)
if [ ! -x \"./setup.sh\" ]; then
    echo -e \"\\033[1;33mℹ️ setup.sh is not executable. Attempting to set permissions...\\033[0m\"
    sudo chmod +x ./setup.sh
    if [ \$? -ne 0 ]; then
        echo -e \"\\033[1;31m✘ Error: Failed to make setup.sh executable. Please check permissions.\\033[0m\"
        exit 1
    fi
fi

echo -e \"\\033[0;36m🚀 Running WireGuard Panel setup (setup.sh)...\\033[0m\"
sudo ./setup.sh \"\$@\" # Pass all arguments to setup.sh

exit \$?
"
    # Write the script
    if echo -e "$script_content" | sudo tee "$wire_script_path" > /dev/null; then
        print_message "$LIGHT_GREEN" "✔ 'wire' script content updated."
    else
        print_message "$LIGHT_RED" "✘ Error: Failed to write 'wire' script to $wire_script_path."
        return 1
    fi

    # Make it executable
    if sudo chmod +x "$wire_script_path"; then
        print_message "$LIGHT_GREEN" "✔ 'wire' script is now executable."
    else
        print_message "$LIGHT_RED" "✘ Error: Failed to make 'wire' script executable."
        return 1
    fi

    # Check if /usr/local/bin is in PATH
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
        print_message "$LIGHT_YELLOW" "⚠️ /usr/local/bin is not in your PATH. Adding it to /etc/profile for future sessions."
        print_message "$LIGHT_YELLOW" "   You might need to run 'source /etc/profile' or re-login for it to take effect in the current session."
        if echo "export PATH=\$PATH:/usr/local/bin" | sudo tee -a /etc/profile > /dev/null; then
            print_message "$LIGHT_GREEN" "✔ /usr/local/bin added to PATH in /etc/profile."
        else
            print_message "$LIGHT_RED" "✘ Error: Failed to add /usr/local/bin to PATH in /etc/profile."
        fi
        # For current session:
        # export PATH=$PATH:/usr/local/bin 
        # print_message "$LIGHT_BLUE" "   Temporarily added /usr/local/bin to PATH for the current session."
    else
        print_message "$LIGHT_GREEN" "✔ /usr/local/bin is already in PATH."
    fi
}

# This function seems specific to an older update process, might need review
# For now, it installs jdatetime if venv exists.
install_dependencies_if_needed() {
    local venv_path="$SCRIPT_INSTALL_DIR/src/venv"
    if [ -d "$venv_path" ]; then
        print_message "$CYAN" "🐍 Checking Python virtual environment at $venv_path..."
        # Activate venv
        print_message "$LIGHT_BLUE" "  Activating virtual environment..."
        source "$venv_path/bin/activate"
        if [ $? -ne 0 ]; then
            print_message "$LIGHT_RED" "  ✘ Error: Couldn't activate the virtual environment. Skipping dependency check."
            return 1
        fi

        print_message "$LIGHT_BLUE" "  Ensuring 'jdatetime' is installed/updated..."
        if pip install --upgrade jdatetime; then
            print_message "$LIGHT_GREEN" "  ✔ 'jdatetime' is up to date."
        else
            print_message "$LIGHT_RED" "  ✘ Error: Failed to install/update 'jdatetime'."
            deactivate
            return 1
        fi
        
        # Add other pip installs here if needed for updates

        deactivate
        print_message "$LIGHT_GREEN" "  ✔ Virtual environment deactivated."
    else
        print_message "$LIGHT_YELLOW" "ℹ️ Python virtual environment not found at $venv_path. Dependency check skipped."
        print_message "$LIGHT_YELLOW" "   The main setup.sh should handle dependency installation."
    fi
}

main() {
    clear
    print_message "$CYAN" "==========================================="
    print_message "$CYAN" "  WireGuard Panel Management Script"
    print_message "$CYAN" "==========================================="
    
    prompt_action  

    case "$ACTION_CHOICE" in
        1) # Update
            install_dependencies_if_needed # Install/update specific deps before main update logic
            update_files
            ;;
        2) # Install/Reinstall
            reinstall_panel
            ;;
        *)
            print_message "$LIGHT_RED" "✘ Invalid choice. Exiting."
            exit 1
            ;;
    esac

    if [ $? -eq 0 ]; then # Check if previous operations were successful
        create_wire_cli_script
        print_message "$LIGHT_GREEN" "🎉 Process completed successfully!"
    else
        print_message "$LIGHT_RED" "❌ Process failed. Please check the error messages above."
    fi
}

# Run the main function
main
