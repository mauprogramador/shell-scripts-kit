#!/bin/bash

YESNO="(\033[32my\033[m/\033[31mn\033[m) [\033[32my\033[m]"
VENV_NAME="\033[m(\033[34;1m.venv\033[m\033[m)"

signalHandler() {
  trap "echo -e '\033[35;1m!\033[m \033[91mGot an interruption ✘\033[m' >&2; exit 1" SIGINT
}

logError() {
  local message="$1"
  echo -e "\033[35;1m!\033[m \033[91m$message\033[91m ✘\033[m" >&2
}

logSuccess() {
  local messagePart1="$1"
  local messagePart2="$2"
  echo -e "\033[93m$messagePart1 \033[92m$messagePart2 \033[92m✔\033[m" >&2
}

exitError() {
  local message="$1"
  logError "$message"
  exit 1
}

echoHelp() {
  echo -e "\033[mTry passing \033[33m--help\033[m for more information.\033[m" >&2
}

furtherInfo() {
  local link="$1"
  echo "For further information visit $link" >&2
  exit 1
}

invalidOption() {
  logError "Invalid option \033[93m-$OPTARG"
  echoHelp
  exit 1
}

handleHelp() {
  local option="$2"

  if [[ "$option" == "--help" ]]; then
    echo -e "$HELP_MANUAL" >&2
    exit 0
  fi

  while getopts ":h" opt; do
    case $opt in
    h)
      echo -e "$HELP_MANUAL" >&2
      exit 0
      ;;
    \?)
      logError "Invalid option \033[93m-$OPTARG\033[91m" >&2
      echo -e "\033[mTry passing \033[33m--help\033[m for further information.\033[m" >&2
      exit 1
      ;;
    esac
  done
}

handleAnswer() {
  if echo "$ANSWER" | grep -Eq '^(y|Y|yes|YES|Yes)$'; then
    return 0
  fi
  return 1
}

checkForGitRepo() {
  if ! { git rev-parse --is-inside-work-tree >/dev/null 2>&1 || [ -d ".git" ]; }; then
    exitError "Invalid or Not found Git repository"
  fi
}

extract_prefix_and_message() {
  local commit_subject="$1"

  if [[ "$commit_subject" =~ ^([^:]+):[[:space:]]*(.*)$ ]]; then
    prefix="${BASH_REMATCH[1]}"
    message="${BASH_REMATCH[2]}"
    echo "$prefix:$message"
  else
    echo "other:$commit_subject"
  fi
}

append_commits_by_group() {
  local title="$1"
  local commits_list="$2"

  if [[ -n "$commits_list" ]]; then
    echo -e "\n$TITLE_LEVEL $title" >>"$OUTPUT_FILE"
    echo "$commits_list" >>"$OUTPUT_FILE"
  fi
}
