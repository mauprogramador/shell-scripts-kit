#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler
checkForGitRepo

# Help
readonly HELP_MANUAL="
Usage: rport [OPTION] [PORT] [RANGE]

Lists the TCP ports in a range and checks the availability of a TCP port.
It will use Netcat (nc) command to check availability.
It will use Socket Statistics (ss) command to list listenning ports.
It will list all listening TCP Ports by default if no arg is provided.

Option and argument:
  port           TCP port to check availability.
  range          Range of TCP ports to list.
  -h, --help     Display this help and exit.

Examples:
  $ rport 2009 (Check if port availability)
  $ rport 2000:2100 (List used ports in range)

Docs:
  Netcat: https://docs.oracle.com/cd/E36784_01/html/E36870/netcat-1.html
  Socket Statistics: https://www.redhat.com/en/blog/socket-stats-ss
"

handleHelp "$1"

# e.g. 2000, 2009
PORT_PATTERN="^[0-9]{1,4}$"

# e.g. 2000:2050
PORT_RANGE_PATTERN="^[0-9]{1,4}\:[0-9]{1,4}$"

# List all listening ports by default
if [ -z "$1" ]; then
  echo -e "\033[93mList all Listening TCP Ports\033[m" >&2
  ss -nlpt
  exit 0
fi

# Check port availability
if [[ "$1" =~ $PORT_PATTERN ]]; then

  if command -v "nc" &>/dev/null; then
    nc -zv localhost "$1" &>/dev/null

    if [ $? -ne 0 ]; then
      logSuccess "TCP Port $1" "is available"
      exit 0
    fi

    socket="$(ss -nlpt | grep ":$1")"
    local="$(echo "$socket" | awk '{print $4}')"
    peer="$(echo "$socket" | awk '{print $5}')"
    process="$(echo "$socket" | awk '{print $NF}')"

    printf "\033[93m%-30s %-30s %s\033[m\n" "Local Address:Port" "Peer Address:Port" "Process"
    printf "%-30s %-30s %s\n" "$local" "$peer" "$process"

    exitError "TCP Port $1 is in use"

  else
    exitError "No Netcat installation found"
  fi

# List ports
elif [[ "$1" =~ $PORT_RANGE_PATTERN ]]; then

  range_start=$(echo "$1" | cut -d':' -f1)
  range_end=$(echo "$1" | cut -d':' -f2)

  echo -e "\033[93mList used TCP Ports ($range_start:$range_end)\033[m" >&2
  printf "%-9s %s\n" "Port" "Status"

  for port in $(seq "$range_start" "$range_end"); do
    nc -zv localhost "$port" &>/dev/null

    if [ $? -ne 0 ]; then
      printf "%-9s \033[92m%s\033[m\n" "$port" "FREE"
    else
      printf "%-9s \033[91m%s\033[m\n" "$port" "USED"
    fi
  done

  exit 0

else
  logError "Invalid TCP Ports value format"
  echoHelp
  exit 1
fi

exit 0
