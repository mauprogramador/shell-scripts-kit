#!/bin/bash

# Import functions
if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler

# Help
readonly HELP_MANUAL="
Usage: adserv [OPTION]

Generates a Systemd service unit file and starts a new service from it.
Interactively prompts for service information and opens the unit file for editing.
Runs a service for an application from the project directory.
Uses the Gedit editor by default if no options are provided.

Options for Systemd Service Unit file:
  gedit          Open with Gedit editor.
  vim            Open with Vim editor.
  nano           Open with Nano editor.
  -h, --help     Display this help and exit.

Example:
  $ adserv (Open and Edit with gedit)

Docs:
  Gedit: https://gedit-text-editor.org/
  Vim: https://www.vim.org/
  Nano: https://www.nano-editor.org
  Systemctl: https://www.commandlinux.com/man-page/man1/systemctl.1.html
  Systemd Unit Files: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_systemd_unit_files_to_customize_and_optimize_your_system/assembly_working-with-systemd-unit-files_working-with-systemd
"

handleHelp "$1"

# e.g. gedit, vim
COMMANDS_PATTERN="^(gedit|vim|nano)$"

# e.g. book-api
NAME_PATTERN="^[a-zA-Z0-9\_\-]+$"

# e.g. Book API
DESCRIPTION_PATTERN="^[a-zA-Z0-9\_ \-]+$"

# Check if allowed command option
if [ -z "$1" ]; then
  chosen_command="gedit"
else
  if echo "$1" | grep -Eq $COMMANDS_PATTERN; then
    chosen_command="$1"
  else
    invalidOption
  fi
fi

if ! command -v "$chosen_command" &>/dev/null; then
  exitError "Command-option \033[33m$1\033[91m not found"
fi

# Check if not sudo
if [[ ! "$UID" -eq 0 ]]; then
  exitError "Not running with sudo. Root privileges required"
fi

# Get paths
echo -e "\033[93mStarting a new Systemd Service\033[m" >&2
current_path=$(pwd)
project_path=$(basename "$current_path")
systemd_dir="$current_path/systemd_service"
echo -e "\033[95;1m-\033[m Project Path: \033[37;1m$project_path\033[m" >&2

# Service name
echo -ne "\033[95;1m-\033[m Service Name (e.g. \033[37;1mbook-api\033[m) [\033[37;1m$project_path\033[m]: "
read service_name

if [[ -z "$service_name" ]]; then
  service_name="$project_path"
fi

if [[ -z "$service_name" ]] || [[ ! "$service_name" =~ $NAME_PATTERN ]]; then
  exitError "Invalid Service Name"
fi

# Service description
echo -ne "\033[95;1m-\033[m Service Description (e.g. \033[37;1mBook API\033[m) [\033[37;1mskip\033[m]: "
read service_description

if [[ -z "$service_description" ]]; then
  service_description="DESCRIPTION"
fi

if [[ -z "$service_description" ]] || [[ ! "$service_description" =~ $DESCRIPTION_PATTERN ]]; then
  exitError "Invalid Service Description"
fi

# Service config file
system_dir="/etc/systemd/system"
service_file="$service_name.service"
service_path="$system_dir/$service_file"

sudo touch "$service_path"
checkCommandExit "Failed to Create Unit file"

sudo chmod 664 "$service_path"
checkCommandExit "Failed to Set Permission"

# Clean in case of error
trap 'handleExitError' ERR

handleExitError() {
  local exit_code=$?
  sudo rm "$service_path" &>/dev/null
  sudo rm -rf "$systemd_dir" &>/dev/null
  echo -e "\033[95;1m!\033[m \033[93mService files cleaned\033[m" >&2
  exit $exit_code
}

# Select Service menu
service_types=("Venv" "Dockerfile" "Docker-Compose" "Makefile" "Base")

echo -e "\033[93mSystemd Service Types:\033[m" >&2
PS3="Select a type: "

select service_type in "${service_types[@]}"; do
  if [[ -n "$service_type" ]]; then
    break
  else
    logError "Invalid option \033[93m$REPLY\033[91m"
  fi
done

echo -e "\033[95;1m-\033[m Service Type: $service_type" >&2

# Handle types
TEMPLATES="$(dirname "$0")/../templates/systemd"

case $service_type in
"Venv") cp "$TEMPLATES/venv.service" "$service_path" &>/dev/null ;;
"Dockerfile") cp "$TEMPLATES/docker-file.service" "$service_path" &>/dev/null ;;
"Docker-Compose") cp "$TEMPLATES/docker-compose.service" "$service_path" &>/dev/null ;;
"Makefile") cp "$TEMPLATES/makefile.service" "$service_path" &>/dev/null ;;
"Base") cp "$TEMPLATES/base.service" "$service_path" &>/dev/null ;;
esac

# Fill info
sed -i "s/DESCRIPTION/$service_description/g" "$service_path" &>/dev/null
sed -i "s/USER/$(logname)/g" "$service_path" &>/dev/null
sed -i "s/PROJECT_DIR/$(escapePath "$current_path")/g" "$service_path" &>/dev/null
sed -i "s/SYSTEMDIR/$(escapePath "$systemd_dir")/g" "$service_path" &>/dev/null

# Get repository URL
origin_url=$(git remote get-url origin 2>/dev/null)

if [[ -n "$origin_url" ]]; then
  sed -i "s/DOCUMENTATION/$(escapePath "$origin_url")/g" "$service_path" &>/dev/null
else
  logError "Failed to get \033[93mOrigin\033[91m URL"
fi

# Unit file created
logSuccess "$service_file" "created"

# Execute command
echo -e "\033[33mEdit the content\033[m" >&2

case $chosen_command in
"gedit") sudo gedit "$service_path" &>/dev/null ;;
"vim") sudo vim "$service_path" ;;
"nano") sudo nano "$service_path" ;;
*) exitError "Invalid command-option" ;;
esac

# Create project Systemd dir
mkdir "$systemd_dir" &>/dev/null
cd "$system_dir"

# Reload Daemon
sudo systemctl daemon-reload &>/dev/null
checkCommandExit "Failed to Reload Daemon"

# Enable Service
sudo systemctl enable "$service_file" &>/dev/null
checkCommandExit "Failed to Enable Service"

# Start Service
sudo systemctl start "$service_file" &>/dev/null
checkCommandExit "Failed to Start Service"

# Create symbolic file
ln -s "$service_path" "$systemd_dir/$service_file" &>/dev/null
logSuccess "Symbolic Unit file" "created"

# Check service status
status=$(sudo systemctl is-active "$service_file")
if [ "$status" == "active" ]; then
  logSuccess "Service $service_name" "is $status"
else
  exitError "Service $service is $status"
fi

# Output
echo -e "Go check the logs in the \033[37;1msystemd_service\033[m directory" >&2

# Show Service Status
sudo systemctl status --no-pager "$service_file"
checkCommandExit "Failed to get Service Status"

exit 0
