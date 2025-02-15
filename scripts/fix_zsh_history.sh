#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler

# Help
readonly HELP_MANUAL="
Usage: fzshist [OPTION]

Fixes a corrupted ZSH history file.
It creates a backup of the corrupted one and moves its contents back.
It reads and loads this newly created fixed history.
Finally, it removes the backup.

Option:
  -h, --help     Display this help and exit.

Docs:
  Source: https://shapeshed.com/zsh-corrupt-history-file/
"

handleHelp "$1"

# Set file names
ZSH_HISTORY="~/.zsh_history"
ZSH_HISTORY_BACKUP="~/.zsh_history_backup"

# Check if zsh history exists
if [[ ! -f "$ZSH_HISTORY" ]]; then
  exitError "No \033[37;1m$ZSH_HISTORY\033[91m file found"
fi

# Create backup
mv "$ZSH_HISTORY" "$ZSH_HISTORY_BACKUP" &>/dev/null
if [[ $? -ne 0 ]]; then
  exitError "Failed to create backup"
fi

# Copy backup content to new history
strings "$ZSH_HISTORY_BACKUP" > "$ZSH_HISTORY" &>/dev/null
if [[ $? -ne 0 ]]; then
  exitError "Failed to copy backup content"
fi

# Read history from the fixed history
fc -R "$ZSH_HISTORY" &>/dev/null
if [[ $? -ne 0 ]]; then
  exitError "Failed to read new history"
fi

# Remove corrupted history
rm "$ZSH_HISTORY_BACKUP" &>/dev/null
if [[ $? -ne 0 ]]; then
  exitError "Failed to remove backup"
fi

# Output
logSuccess "ZSH history" "fixed"

exit 0
