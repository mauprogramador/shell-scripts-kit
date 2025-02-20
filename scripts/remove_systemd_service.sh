#!/bin/bash

# Import functions
if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler

# Check if not sudo
if [[ ! "$UID" -eq 0 ]]; then
  exitError "Not running with sudo. Root privileges required"
fi

# Help
readonly HELP_MANUAL="
Usage: rmserv [OPTION] [SERVICE]

Removes a running Systemd Service and its files.
Gets the Service name from the project directory.
Interactively prompts for the service name by default if none is provided.

Option and argument:
  service        Systemd Service name.
  -h, --help     Display this help and exit.

Example:
  $ rmserv book-api (Remove service)

Docs:
  Systemctl: https://www.commandlinux.com/man-page/man1/systemctl.1.html
  Systemd Unit Files: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_systemd_unit_files_to_customize_and_optimize_your_system/assembly_working-with-systemd-unit-files_working-with-systemd
"

handleHelp "$1"

# e.g. book-api
NAME_PATTERN="^[a-zA-Z0-9\_\-]+$"

# Get paths
echo -e "\033[93mRemoving a Systemd Service\033[m" >&2
current_path=$(pwd)
project_path=$(basename "$current_path")
systemd_dir="$current_path/systemd_service"

# Service name
if [[ -n "$1" ]]; then
  echo -e "\033[95;1m-\033[m Service Name: \033[37;1m$1\033[m"
  service_name="$1"
else
  logError "No Service Name provided"

  echo -ne "\033[95;1m-\033[m Service Name (e.g. \033[37;1mbook-api\033[m) [\033[37;1m$project_path\033[m]: "
  read service_name

  if [[ -z "$service_name" ]]; then
    service_name="$project_path"
  fi
fi

if [[ -z "$service_name" ]] || [[ ! "$service_name" =~ $NAME_PATTERN ]]; then
  exitError "Invalid Service Name"
fi

# Service config file
system_dir="/etc/systemd/system"
service_file="$service_name.service"
service_path="$system_dir/$service_file"

# Check if Service exists
sudo systemctl status "$service_file" &>/dev/null
if [[ $? -ne 0 ]]; then
  exitError "Service $service_file not found"
fi

# Stop Service
sudo systemctl stop "$service_file" &>/dev/null
checkCommandExit "Failed to Stop Service"

# Disable Service
sudo systemctl disable "$service_file" &>/dev/null
checkCommandExit "Failed to Disable Service"

# Reload Daemon
sudo systemctl daemon-reload &>/dev/null
checkCommandExit "Failed to Reload Daemon"

# Remove Service Unit file
if [ -f "$service_path" ]; then
  sudo rm "$service_path" &>/dev/null
  logSuccess "Service Unit file" "removed"
else
  exitError "Service Unit file not Found"
fi

# Remove Systemd folder
if [ -d "$systemd_dir" ]; then
  sudo rm -rf "$systemd_dir" &>/dev/null
  logSuccess "Systemd Service folder" "removed"
else
  exitError "Failed to Remove Systemd Service folder"
fi

# Output
logSuccess "Service $service_file" "disabled"

exit 0
