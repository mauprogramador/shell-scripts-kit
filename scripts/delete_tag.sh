#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler
checkForGitRepo

# Help
readonly HELP_MANUAL="
Usage: dtag [OPTION] [TAG]

Deletes a Git tag locally and remotely (pushes the delete to origin).
It prompts for a tag interactively by default if no tag argument is provided.

Option and argument:
  tag            Git tag to be deleted.
  -h, --help     Display this help and exit.

Tag format:
  vx.x.x         e.g. v0.1.0
  vx.x.x-x       e.g. v0.1.0-alpha

Example:
  $ dtag v0.1.4 (Delete)

Docs:
  Git Tags: https://git-scm.com/book/en/v2/Git-Basics-Tagging
"

handleHelp "$1"

# e.g. 0.1.12, 0.2.106-alpha
TAG_REGEX_PATTERN="v[0-9]+\.[0-9]+\.[0-9]+[\-\w-]*"

# Check passed tag
tag=""

if [[ -n "$1" ]]; then
  if [[ ! "$1" =~ $TAG_REGEX_PATTERN ]]; then
    logError "Invalid tag format"
    echoHelp
    exit 1
  elif ! git show-ref --verify "refs/tags/$1" &>/dev/null; then
    exitError "Git Tag not found"
  else
    tag="$1"
    logSuccess "Git Tag $1" "selected"
  fi
fi

# If tag is not provided
if [[ -z "$tag" ]]; then
  logError "No Git Tag provided"

  # Get all Git tags
  tags=$(git tag -l)

  # If no tags are found
  if [[ -z "$tags" ]]; then
    exitError "No Git tags found"
  fi

  # Store tags
  found_tags=()
  while IFS= read -r git_tag; do
    found_tags+=("$git_tag")
  done <<<"$tags"

  # Select tag menu
  echo "Git tags found:" >&2
  PS3="Select a tag: "

  select git_tag in "${found_tags[@]}"; do
    if [[ -n "$git_tag" ]]; then
      tag="$git_tag"
      break
    else
      logError "Invalid option \033[93m$REPLY\033[91m"
    fi
  done

  logSuccess "Git Tag $git_tag" "selected"
fi

# Delete Tag
git tag -d "$tag" &>/dev/null
if [ $? -ne 0 ]; then
  exitError "Failed to delete Tag"
fi

# Delete remote Tag
git push origin --delete "$tag" &>/dev/null
if [ $? -ne 0 ]; then
  exitError "Failed to delete remote Tag"
fi

# Output
logSuccess "Git Tag $tag" "removed"
echo -e "Go and check it out at \033[37;1mOrigin\033[m" >&2

# Get origin
origin_url=$(git remote get-url origin 2>/dev/null)

if [[ -n "$origin_url" ]]; then
  origin_url="$(echo "$origin_url" | sed "s/\.git$//")"
  echo -e "$origin_url/tags" >&2
else
  logError "Failed to get \033[93mOrigin\033[91m URL"
fi

exit 0
