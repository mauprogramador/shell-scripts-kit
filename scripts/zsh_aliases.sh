#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler

# Help
readonly HELP_MANUAL="
Usage: zshalias [OPTION]

Edits and updates the ZSH aliases file.
It opens the file with an editor and moves its contents to the one in home.
It updates the home ZSH aliases file by default if no options are given.

Options for aliases file:
  gedit          Open with Gedit editor.
  vim            Open with Vim editor.
  nano           Open with Nano editor.
  update         Update home ZSH aliases.
  -h, --help     Display this help and exit.

Example:
  $ zshalias gedit (Open file)

Docs:
  ZSH: https://github.com/ohmyzsh/ohmyzsh/wiki
  Gedit: https://gedit-text-editor.org/
  Vim: https://www.vim.org/
  Nano: https://www.nano-editor.org
"

handleHelp "$1"

# Set file names
ZSH_ALIASES=".zsh_aliases"
LOCAL_ZSH_ALIASES="$(dirname "$0")/../config/.zsh_aliases"
HOME_ZSH_ALIASES="$HOME/.zsh_aliases"

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
  dir_path="$(dirname $(dirname $(realpath "$0")))"
  echo -e "KIT_PATH=$dir_path\n" >$HOME_ZSH_ALIASES
  cat "$LOCAL_ZSH_ALIASES" >>$HOME_ZSH_ALIASES
  logSuccess "ZSH aliases" "updated"
  echo -e "Run \033[93msource ~/.zsh_aliase\033[m to load aliases"
  ;;
"gedit")
  echo -e "\033[33mEdit and save (Ctrl + S)\033[m" >&2
  gedit $LOCAL_ZSH_ALIASES
  ;;
"vim")
  echo -e "\033[33mEdit and save\033[m" >&2
  vim $LOCAL_ZSH_ALIASES
  ;;
"nano")
  echo -e "\033[33mEdit and save\033[m" >&2
  nano $LOCAL_ZSH_ALIASES
  ;;
*)
  exitError "Invalid command-option"
  ;;
esac

exit 0
