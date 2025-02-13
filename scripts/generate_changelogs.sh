#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler
checkForGitRepo

# Help
readonly HELP_MANUAL="
Usage: changelog [OPTION]

Generates the Git CHANGELOG of all changes in the project, grouped by released tags and last unreleased changes, and with updates sorted by conventional commits.

It writes a CHANGELOG.md file by default if no option is provided.

Options for the CHANGELOG content:

  gedit          Open with Gedit editor. https://gedit-text-editor.org/
  cat            Read with Cat command. https://www.gnu.org/software/coreutils/cat
  vim            Open with Vim editor. https://www.vim.org/
  nano           Open with Nano editor. https://www.nano-editor.org
  xclip          Copy with XClip command. https://github.com/astrand/xclip
  -h, --help     Display this help and exit.

Example:
  $ changelog xclip (Copy to clipboard)
"

handleHelp "$1"

# Check if allowed command option
if [ -z "$1" ]; then
  chosen_command="file"
else
  if echo "$1" | grep -Eq '^(cat|gedit|vim|nano|xclip)$'; then
    chosen_command="$1"
  else
    invalidOption
  fi
fi

if [[ "$chosen_command" != "file" ]] && ! command -v "$chosen_command" &>/dev/null; then
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

# Add h1 title
echo "# 📜 Changelog ($(date "+%Y-%m-%d"))" >>$OUTPUT_FILE

# Get first commit date
first_commit=$(git log --reverse --all --pretty=format:"%cs" | head -n 1)

if [[ -z "$first_commit" ]]; then
  logError "First commit date not found"
else
  first_commit_date=$(LC_ALL=en_US date -d $first_commit "+%B %d, %Y")
  echo -e "\n> In development since: $first_commit_date." >>$OUTPUT_FILE
fi

# Get all Git tags
tags=$(git tag)

if [[ -z "$tags" ]]; then
  logError "No Git tags found"
else
  tag_list=""
  while IFS= read -r tag; do
    if [[ -n "$tag_list" ]]; then
      tag_list+=", "
    fi
    tag_list+="[\`$tag\`](#$tag)"
  done <<<"$tags"

  echo -e "\n> Tags: $tag_list." >>$OUTPUT_FILE
fi

# Build unreleased changes section
unreleased_commits=$(git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"%h %H %cs %s")

if [[ -n "$unreleased_commits" ]]; then
  echo -e "\n## 🔥 Latest Unreleased" >>$OUTPUT_FILE

  feat_commits=""
  fix_commits=""
  chore_commits=""
  build_commits=""
  style_commits=""
  refactor_commits=""
  test_commits=""
  docs_commits=""
  other_commits=""

  while read -r short_hash commit_hash short_date subject; do
    formatted_subject=$(extract_prefix_and_message "$subject")
    prefix="${formatted_subject%%:*}"
    message="${formatted_subject#*:}"

    message="$(echo "${message:0:1}" | tr '[:lower:]' '[:upper:]')${message:1}"
    text=$(echo -e "\n- $message. [#$short_hash]($origin_url/commit/$commit_hash) ($short_date)")

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
  done <<<"$unreleased_commits"

  TITLE_LEVEL="###"
  append_commits_by_group "🔨 Builds" "$build_commits"
  append_commits_by_group "✨ Features" "$feat_commits"
  append_commits_by_group "🔧 Fixes" "$fix_commits"
  append_commits_by_group "♻️ Refactors" "$refactor_commits"
  append_commits_by_group "🧪 Tests" "$test_commits"
  append_commits_by_group "📝 Chores" "$chore_commits"
  append_commits_by_group "📄 Docs" "$docs_commits"
  append_commits_by_group "🎨 Styles" "$style_commits"
  append_commits_by_group "📌 Others" "$other_commits"
fi

# Build tag changes sections
tags=$(git for-each-ref --sort=-taggerdate --format '%(refname:short) %(taggerdate:short)' refs/tags)

while read -r tag tag_date; do
  echo -e "\n## 🔖 Release [\`$tag\`]($origin_url/releases/tag/$tag) ($tag_date) <span id='$tag'></span>" >>$OUTPUT_FILE

  feat_commits=""
  fix_commits=""
  chore_commits=""
  build_commits=""
  style_commits=""
  refactor_commits=""
  test_commits=""
  docs_commits=""
  other_commits=""

  previous_tag=$(git describe --tags --abbrev=0 "$tag"^ 2>/dev/null)

  if [ -z "$previous_tag" ]; then
    released_commits=$(git log "$tag" --pretty=format:"%h %H %cs %s")
  else
    released_commits=$(git log "$previous_tag".."$tag" --pretty=format:"%h %H %cs %s")

    compare_url="$origin_url/compare/$previous_tag...$tag"
    echo -e "\n> See the [comparison ⟲ history]($compare_url) with the previous tag." >>$OUTPUT_FILE
  fi

  if [[ -z "$released_commits" ]]; then
    exitError "Failed to get released commits"
  fi

  while read -r short_hash commit_hash short_date subject; do
    formatted_subject=$(extract_prefix_and_message "$subject")
    prefix="${formatted_subject%%:*}"
    message="${formatted_subject#*:}"

    message="$(echo "${message:0:1}" | tr '[:lower:]' '[:upper:]')${message:1}"
    text=$(echo -e "\n- $message. [#$short_hash]($COMMIT_LINK/$commit_hash) ($short_date)")

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

done <<<"$tags"

logSuccess "CHANGELOG" "generated"

# Execute command
case $chosen_command in
"file")
  cat "$OUTPUT_FILE" >"CHANGELOG.md"
  echo -e "\033[33mCheck it out at \033[37;1mCHANGELOG.md\033[m file" >&2
  ;;
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

exit 0
