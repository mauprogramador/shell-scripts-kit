#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler
checkForGitRepo

# Help
readonly HELP_MANUAL="
Usage: ptag [OPTION] [TAG]

Creates a new Git tag to mark a release point for project updates and pushes it to origin.
It prompts for a tag interactively by default if no tag argument is provided.

Option and argument:
  tag            New Git tag to be pushed.
  -h, --help     Display this help and exit.

Tag format:
  vx.x.x         e.g. v0.1.0
  vx.x.x-x       e.g. v0.1.0-alpha

Example:
  $ ptag v0.1.4 (Create and push)

Docs:
  Git Tags: https://git-scm.com/book/en/v2/Git-Basics-Tagging
"

handleHelp "$1"

# e.g. 0.1.12, 0.2.106-alpha
TAG_REGEX_PATTERN="^v[0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\_\-]*$"

# Check passed tag
new_tag=""

if [[ -n "$1" ]]; then
  if [[ ! "$1" =~ $TAG_REGEX_PATTERN ]]; then
    logError "Invalid tag format"
    echoHelp
    exit 1
  elif git show-ref --verify "refs/tags/$1" &>/dev/null; then
    exitError "Git tag $1 already exists"
  else
    new_tag="$1"
  fi
fi

# Check for last tag
last_tag=$(git describe --tags --abbrev=0 2>/dev/null)

if [ -z "$last_tag" ]; then
  logError "No Tags found"
else
  echo -e "Last Tag: \033[92;1m$last_tag\033[m" >&2
fi

# New tag
if [ -z "$1" ]; then
  echo -ne "New Tag (Format: \033[37;1mvx.x.x\033[m or \033[37;1mvx.x.x-x\033[m): \033[92;1m"
  read new_tag

  if [[ ! "$new_tag" =~ $TAG_REGEX_PATTERN ]]; then
    logError "Invalid tag format"
    echoHelp
    exit 1
  elif git show-ref --verify "refs/tags/$new_tag" &>/dev/null; then
    exitError "Git tag $new_tag already exists"
  fi
else
  echo -e "\033[mNew Tag: \033[92;1m$new_tag\033[m" >&2
fi

# Create Tag
git tag "$new_tag" -m "🔖 Release version ${new_tag:1}" 2>/dev/null
if [ $? -ne 0 ]; then
  exitError "Failed to create Tag"
fi

# Push Tag
git push origin "$new_tag" 2>/dev/null
if [ $? -ne 0 ]; then
  exitError "Failed to Push to Origin"
fi

# Output
logSuccess "Git Tag $new_tag" "pushed"
echo -e "Go and check it out at \033[37;1mOrigin\033[m" >&2

# Get origin
origin_url=$(git remote get-url origin 2>/dev/null)

if [[ -n "$origin_url" ]]; then
  origin_url="$(echo "$origin_url" | sed "s/\.git$//")"
  echo -e "$origin_url/releases/tag/$new_tag" >&2
else
  logError "Failed to get \033[93mOrigin\033[91m URL"
fi

exit 0
