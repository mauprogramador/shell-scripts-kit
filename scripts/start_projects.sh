#!/bin/bash

# Set logging files
LOG_FOLDER="$(pwd)/logs"
PROJECTS_LOG_FILE="$LOG_FOLDER/projects-logs.log"
POPUP_SUMMARY="Projects"
PID_LOG_FILE="pids.log"

# Set logger
log() {
	case $1 in
	true) echo "$(date +"%d-%m-%Y %H:%M:%S") 🟢  INFO: $2" >> $PROJECTS_LOG_FILE ;;
	false) echo "$(date +"%d-%m-%Y %H:%M:%S") 🔴 ERROR: $2" >> $PROJECTS_LOG_FILE ;;
	*) echo "$1" >> $PROJECTS_LOG_FILE ;;
	esac
}

if [ ! -d "$LOG_FOLDER" ]; then
	mkdir "$LOG_FOLDER"
fi

# Find git repositories in the current directory
repos=$(find . -name ".git" -type d)

if [[ -s $PROJECTS_LOG_FILE ]]; then
	log "\n=== $(date -u) ===\n" >> $PROJECTS_LOG_FILE
fi

if [ -z "$repos" ]; then
	log false "No Git repositories found in the current directory"
	notify-send -u critical -t 5 $POPUP_SUMMARY "No Git repositories found"
	exit 1
fi

log true "Git repositories found!"
projects_pids=""

# Loop over Git repositories
for repo in $repos; do
	repo_dir="$(dirname "$repo")"
	repo_name="$(basename "$repo_dir")"
	repo_log_file="$LOG_FOLDER/$repo_name.log"

	log true "Repository: $repo_dir"
	cd "$repo_dir"

	if [[ -s $repo_log_file ]]; then
		log "\n=== $(date -u) ===\n" >> $repo_log_file
	fi

	echo "=== ⇅ Git Fetch & Pull Origin ⇅ ===" >> $repo_log_file
	log true "▸ Fetch & Pull Origin"

	git fetch origin >> $repo_log_file 2>&1
	git pull origin >> $repo_log_file 2>&1

	if [ -d ".venv" ]; then
		source .venv/bin/activate

		echo "=== 🚀 Starting Application 🚀 ===" >> $repo_log_file
		make run >> $repo_log_file 2>&1 &

		subprocess_pid="$!"
		projects_pids+="$(echo -e "Repository: $repo_dir. PID: [$subprocess_pid]\n")"

		log true "▸ Run in Venv [$subprocess_pid]"
		notify-send -u normal -t 5 $POPUP_SUMMARY "Running <b>$repo_name</b> in <b>Venv</b> [<u>$subprocess_pid</u>]"
	else
		log false "▸ Venv not found"
		notify-send -u critical -t 5 $POPUP_SUMMARY "Venv not found in <b>$repo_dir</b> repository"
	fi

	cd ".."
done

echo $projects_pids	> $PID_LOG_FILE
notify-send -u normal -t 5 $POPUP_SUMMARY "Projects <b>log messages</b> in <b>./logs</b>"
