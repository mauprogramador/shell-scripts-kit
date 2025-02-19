#!/bin/bash

# Import functions
if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler

# Help
readonly HELP_MANUAL="
Usage: adsgp [OPTION]

Generates a Systemd group target file and enables it.
Interactively prompts for group information and opens the target file for editing.
Uses the Gedit editor by default if no options are provided.

Options for Systemd Group Target file:
  gedit          Open with Gedit editor.
  vim            Open with Vim editor.
  nano           Open with Nano editor.
  -h, --help     Display this help and exit.

Example:
  $ adsgp (Open and Edit with gedit)

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

# Start
echo -e "\033[93mCreate a new Systemd Group\033[m" >&2

# Group name
echo -ne "\033[95;1m-\033[m Group Name (e.g. \033[37;1mbook-store\033[m): "
read group_name

if [[ -z "$group_name" ]] || [[ ! "$group_name" =~ $NAME_PATTERN ]]; then
  exitError "Invalid Group Name"
fi

# Group description
echo -ne "\033[95;1m-\033[m Group Description (e.g. \033[37;1mBook Store\033[m) [\033[37;1mskip\033[m]: "
read group_description

if [[ -z "$group_description" ]]; then
  group_description="DESCRIPTION"
fi

if [[ -z "$group_description" ]] || [[ ! "$group_description" =~ $DESCRIPTION_PATTERN ]]; then
  exitError "Invalid Group Description"
fi

# Group config file
system_dir="/etc/systemd/system"
group_file="$group_name-group.target"
group_path="$system_dir/$group_file"

sudo touch "$group_path"
checkCommandExit "Failed to Create Group file"

sudo chmod 664 "$group_path"
checkCommandExit "Failed to Set Permission"

# Clean in case of error
trap 'handleExitError' ERR

handleExitError() {
  local exit_code=$?
  sudo rm "$group_path" &>/dev/null
  echo -e "\033[95;1m!\033[m \033[93mGroup file removed\033[m" >&2
  exit $exit_code
}

# Fill info
templates="$(dirname "$0")/../templates/systemd"
cp "$templates/group.target" "$group_path" &>/dev/null
sed -i "s/DESCRIPTION/$group_description/g" "$group_path" &>/dev/null

# Target file created
logSuccess "$group_file" "created"

# Execute command
echo -e "\033[33mEdit the content\033[m" >&2

case $chosen_command in
"gedit") sudo gedit "$group_path" &>/dev/null ;;
"vim") sudo vim "$group_path" ;;
"nano") sudo nano "$group_path" ;;
*) exitError "Invalid command-option" ;;
esac

# Go to Systemd dir
cd "$system_dir"

# Reload Daemon
sudo systemctl daemon-reload &>/dev/null
checkCommandExit "Failed to Reload Daemon"

# Enable Group
sudo systemctl enable "$group_file" &>/dev/null
checkCommandExit "Failed to Enable Group"

# Output
echo -e "Go check the \033[37;1m$group_file\033[m Group Target file" >&2

exit 0
