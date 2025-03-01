#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler
checkForGitRepo

# Help
readonly HELP_MANUAL="
Usage: release [OPTION]

Generates the Git release notes from the previous tag or changes to the current or latest tag.
The latest updates are grouped and sorted by conventional commits.
It uses the Cat command by default if no option is provided.

Options for the temporary file and its contents:
  gedit          Open with Gedit editor.
  cat            Read with Cat command.
  vim            Open with Vim editor.
  nano           Open with Nano editor.
  xclip          Copy with XClip command.
  -h, --help     Display this help and exit.

Example:
  $ release xclip (Copy to clipboard)

Docs:
  Gedit: https://gedit-text-editor.org/
  Cat: https://www.gnu.org/software/coreutils/cat
  Vim: https://www.vim.org/
  Nano: https://www.nano-editor.org
  XClip: https://github.com/astrand/xclip
"

handleHelp "$1"

# e.g. cat, gedit
COMMANDS_PATTERN="^(cat|gedit|vim|nano|xclip)$"

# Check if allowed command option
if [ -z "$1" ]; then
  chosen_command="cat"
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

# Create temp file
OUTPUT_FILE=$(mktemp) || {
  exitError "Error in creating temp file"
}

# Get remote/origin
origin_url=$(git remote get-url origin 2>/dev/null)

if [[ -n "$origin_url" ]]; then
  origin_url="$(echo "$origin_url" | sed "s/\.git$//")"
else
  exitError "Failed to get \033[93mOrigin\033[91m URL"
fi

# Get latest tag
latest_tag=$(git for-each-ref --count=1 --sort=-taggerdate --format '%(refname:short) %(taggerdate:short)' refs/tags)
if [[ -z "$latest_tag" ]]; then
  exitError "Failed to get the latest Tag"
fi

tag=$(echo "$latest_tag" | awk '{print $1}')
date=$(echo "$latest_tag" | awk '{print $2}')

# Add h1 title
echo -e "# 🔖 Release [\`$tag\`]($origin_url/releases/tag/$tag) ($date)" >>$OUTPUT_FILE

# Check for CHANGELOG
CHANGELOG_FILES=("CHANGELOG.md" "changelog.md" "CHANGELOG" "changelog")

for file in "${CHANGELOG_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "\n> See the [⟲ CHANGELOG]($origin_url/tree/master/$file) to see all the commits." >>$OUTPUT_FILE
    break
  fi
done

# Get previous tag, comparison and commits
previous_tag=$(git describe --tags --abbrev=0 "$tag"^ 2>/dev/null)

if [ -z "$previous_tag" ]; then
  released_commits=$(git log "$tag" --pretty=format:"%h %H %s")

  # Get first commit date
  first_commit=$(git log --reverse --all --pretty=format:"%cs" | head -n 1)

  if [[ -z "$first_commit" ]]; then
    logError "First commit date not found"
  else
    first_commit_date=$(LC_ALL=en_US date -d $first_commit "+%B %d, %Y")
    echo -e "\n> In development since: $first_commit_date." >>$OUTPUT_FILE
  fi
else
  released_commits=$(git log "$previous_tag".."$tag" --pretty=format:"%h %H %s")

  compare_url="$origin_url/compare/$previous_tag...$tag"
  echo -e "\n> See the [comparison ⟲ history]($compare_url) with the previous tag." >>$OUTPUT_FILE
fi

if [[ -z "$released_commits" ]]; then
  exitError "Failed to get released commits"
fi

# Define human-readable notes for main changes
echo -e "\n## 🔥 Main Changes\n\n-" >>$OUTPUT_FILE

# Build releases
feat_commits=""
fix_commits=""
chore_commits=""
build_commits=""
style_commits=""
refactor_commits=""
test_commits=""
docs_commits=""
other_commits=""

while read -r short_hash commit_hash subject; do
  formatted_subject=$(extract_prefix_and_message "$subject")
  prefix="${formatted_subject%%:*}"
  message="${formatted_subject#*:}"

  message="$(echo "${message:0:1}" | tr '[:lower:]' '[:upper:]')${message:1}"
  text=$(echo -e "\n- $message. [#$short_hash]($origin_url/commit/$commit_hash)")

  case $prefix in
  "feat") feat_commits+="$text" ;;
  "fix") fix_commits+="$text" ;;
  "chore") chore_commits+="$text" ;;
  "build") build_commits+="$text" ;;
  "style") style_commits+="$text" ;;
  "refactor") refactor_commits+="$text" ;;
  "test") test_commits+="$text" ;;
  "docs") docs_commits+="$text" ;;
  *) other_commits+="$text" ;;
  esac
done <<<"$released_commits"

TITLE_LEVEL="##"
append_commits_by_group "🔨 Builds" "$build_commits"
append_commits_by_group "✨ Features" "$feat_commits"
append_commits_by_group "🔧 Fixes" "$fix_commits"
append_commits_by_group "♻️ Refactors" "$refactor_commits"
append_commits_by_group "🧪 Tests" "$test_commits"
append_commits_by_group "📝 Chores" "$chore_commits"
append_commits_by_group "📄 Docs" "$docs_commits"
append_commits_by_group "🎨 Styles" "$style_commits"
append_commits_by_group "📌 Others" "$other_commits"

# Output
logSuccess "Release Notes" "generated"

# Execute command
case $chosen_command in
"cat")
  cat "$OUTPUT_FILE"
  echo -e "\033[33mCopy the content (Ctrl + Shift + C)\033[m" >&2
  ;;
"gedit")
  echo -e "\033[33mCopy the content (Ctrl + A & Ctrl + C)\033[m" >&2
  gedit $OUTPUT_FILE
  ;;
"vim")
  echo -e "\033[33mCopy the content\033[m" >&2
  vim $OUTPUT_FILE
  ;;
"nano")
  echo -e "\033[33mCopy the content (Ctrl + C)\033[m" >&2
  nano $OUTPUT_FILE
  ;;
"xclip")
  echo -e "\033[33mPaste the content (Ctrl + V)\033[m" >&2
  cat "$OUTPUT_FILE" | xclip -selection clipboard
  ;;
*)
  logError "Invalid command-option"
  rm $OUTPUT_FILE
  exit 1
  ;;
esac

# Delete temp file
rm $OUTPUT_FILE

# Show release url
echo -e "Go to \033[37;1mOrigin\033[m and create the release notes" >&2
echo -e "$origin_url/releases/tag/$tag" >&2

exit 0
