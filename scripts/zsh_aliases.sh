#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler

# Help
readonly HELP_MANUAL="
Usage: zshalias [OPTION]

Edits and updates the ZSH aliases file. It opens the file with an editor and moves its contents to the one in home.

It updates the home ZSH aliases file by default if no options are given.

Options for aliases file:

  gedit          Open with Gedit editor. https://gedit-text-editor.org/
  vim            Open with Vim editor. https://www.vim.org/
  nano           Open with Nano editor. https://www.nano-editor.org
  update         Update home ZSH aliases.
  -h, --help     Display this help and exit.

Example:
  $ zshalias gedit (Open file)
"

handleHelp "$1"

# Set file names
ZSH_HISTORY=".zsh_aliases"
LOCAL_ZSH_HISTORY="config/.zsh_aliases"
HOME_ZSH_HISTORY="$HOME/.zsh_aliases"

# Check if allowed command option
if [ -z "$1" ]; then
  chosen_command="update"
else
  if echo "$1" | grep -Eq '^(gedit|vim|nano|update)$'; then
    chosen_command="$1"
  else
    invalidOption
  fi
fi

if [[ "$chosen_command" != "update" ]] && ! command -v "$chosen_command" &>/dev/null; then
  exitError "Command-option \033[33m$1\033[91m not found"
fi

# Execute command
case $chosen_command in
"update")
  echo -e "KIT_PATH=$(pwd)\n" >$HOME_ZSH_HISTORY
  cat "$LOCAL_ZSH_HISTORY" >>$HOME_ZSH_HISTORY
  source $HOME_ZSH_HISTORY
  logSuccess "ZSH history" "updated"
  ;;
"gedit")
  echo -e "\033[33mEdit and save (Ctrl + S)\033[m" >&2
  gedit $LOCAL_ZSH_HISTORY
  ;;
"vim")
  echo -e "\033[33mEdit and save\033[m" >&2
  vim $LOCAL_ZSH_HISTORY
  ;;
"nano")
  echo -e "\033[33mEdit and save\033[m" >&2
  nano $LOCAL_ZSH_HISTORY
  ;;
*)
  exitError "Invalid command-option"
  ;;
esac

exit 0
