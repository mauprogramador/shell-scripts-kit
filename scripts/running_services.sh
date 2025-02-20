#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler

# Help
readonly HELP_MANUAL="
Usage: rserv [OPTION] [NAME] [RANGE]

Generates the Git release notes from the previous tag or changes to the current or latest tag.
The latest updates are grouped and sorted by conventional commits.
It uses the Cat command by default if no option is provided.

It will use Systemctl command to check availability.
It will use Socket Statistics (ss) command to list listenning ports.
It will list all listening TCP Ports by default if no arg is provided.

Options and arguments:
  name           Systemd Service name to check activity.
  range          Range of TCP ports of Systemd Services to list.
  --all          List all Systemd Services of all states.
  -h, --help     Display this help and exit.

Examples:
  $ rserv book-store (Check Service activity)
  $ rserv 2000:2100 ()

Docs:
  Systemctl:
  SS: https://www.redhat.com/en/blog/socket-stats-ss
"

handleHelp "$1"

# e.g. spotify
SERVICE_NAME_PATTERN="^[a-zA-Z0-9\_\-]+$"

# e.g. book-store.target
GROUP_NAME_PATTERN="^[a-zA-Z0-9\_\-]+\.target$"

# e.g. 2000:2050
PORT_RANGE_PATTERN="^[0-9]{1,4}\:[0-9]{1,4}$"

# List all running services
if [ -z "$1" ]; then
  echo -e "\033[93mList all Running Systemd Services\033[m"
  systemctl list-units --no-pager --type=service --state=running
  exit 0
fi

# List all services
if [ "$1" == "all" ]; then
  echo -e "\033[93mList all Systemd Services\033[m"
  systemctl list-units --no-pager --type=service
  exit 0
fi

# Check if service is active
if [[ "$1" =~ $SERVICE_NAME_PATTERN ]]; then
  status="$(systemctl is-active "$1")"
  if [ "$status" == "active" ]; then

    echo -e "\033[93mSystemd Service Properties\033[m"
    properties="Id,Names,MainPID,LoadState,ActiveState,SubState,ExecMainStartTimestamp,Description,ControlGroup,Group"
    systemctl show -p $properties "$1".service

    main_pid="$(systemctl show -p MainPID --value "$1".service)"
    pids=($(pgrep -g "$main_pid"))

    if [[ ${#pids[@]} -gt 0 ]]; then
      echo "Processes="
      echo -e "\033[93mState  Recv-Q Send-Q     Local-Addr           Peer-Addr    Process\033[m"

      for pid in "${pids[@]}"; do

        socket="$(ss -nlpt | grep "$pid")"
        if [ -n "$socket" ]; then
          echo "$socket"
        fi
      done

    else
      logError "No processes found for $1.service"
    fi

    logSuccess "Service $1" "is $status"
    exit 0
  else
    exitError "Service $1 is $status"
  fi

# List services by group
elif [[ "$1" =~ $GROUP_NAME_PATTERN ]]; then
  echo -e "\033[93mList $(echo "$1" | cut -d'.' -f1) Group Systemd Services\033[m"
  systemctl list-units --no-pager --type=service --filter=PartOf="$1"
  exit 0

# List services by port range
elif [[ "$1" =~ $PORT_RANGE_PATTERN ]]; then

  range_start=$(echo "$1" | cut -d':' -f1)
  range_end=$(echo "$1" | cut -d':' -f2)

  # UNIT, LOAD, ACTIVE, SUB, Local Address:Port, Peer Address:Port, Process

  echo -e "\033[93mList Systemd Services ($range_start:$range_end)\033[m"
  printf "%-10s %-7s %-30s %s\n" "PID" "Port" "Service" "Properties"

  for port in $(seq "$range_start" "$range_end"); do

    pid=$(ss -nlpt | grep ":$port" | awk '{print $NF}' | sed -n 's/.*pid=\(.*\)\,.*/\1/p')

    if [ -n "$pid" ]; then
      main_pid=$(ps -o pgid= -p "$pid")

      unit=$(systemctl status "$main_pid" 2>/dev/null | grep "Loaded:" | sed -n 's/.*\/etc\/systemd\/system\/\(.*\)\.service.*/\1/p')
      props=$(systemctl show -p LoadState,ActiveState,SubState "$unit.service" | sed ':a;N;$!ba;s/\n/\, /g')

      printf "%-10s %-7s %-30s %s\n" "$main_pid" "$port" "$unit" "$props"
    fi
  done
  exit 0

else
  logError "Invalid Ports range value format"
  echoHelp
  exit 1
fi

exit 0
