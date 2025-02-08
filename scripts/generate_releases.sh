#!/bin/bash

trap "echo -e '\033[35;1m!\033[m \033[91mGot an interruption ✘\033[m' ; exit 1" SIGINT

# Help
readonly HELP="
Usage: release [OPTION]

Generates Git release notes from the previous tag or changes to the current or latest tag, with the latest updates sorted by conventional commits.

Options for the temporary file and its contents

  gedit          Open with Gedit editor https://gedit-text-editor.org/
  cat            Read with Cat command https://www.gnu.org/software/coreutils/cat
  nano           Open with Nano editor https://www.nano-editor.org
  xclip          Copy with XClip command https://github.com/astrand/xclip

  -h, --help     Display this help and exit
"

if [[ "$1" == "--help" ]]; then
  echo "$HELP" >&2
  exit 0
fi

while getopts ":h" opt; do
  case $opt in
    h)
      echo "$HELP" >&2
      exit 0
      ;;
    \?)
      echo -e "\033[35;1m!\033[m \033[91mInvalid option -$OPTARG ✘\033[m" >&2
      exit 1
      ;;
  esac
done

# Check the allowed command option
ALLOWED_COMMANDS=("gedit" "cat" "nano" "xclip")
DEFAULT_COMMAND="cat"

if [ -z "$1" ]; then
  chosen_command="$DEFAULT_COMMAND"
else
  valid_command=false
  for cmd in "${ALLOWED_COMMANDS[@]}"; do
    if [[ "$1" == "$cmd" ]]; then
      valid_command=true
      chosen_command="$1"
      break
    fi
  done

  if ! $valid_command; then
    echo -e "\033[35;1m!\033[m \033[91mInvalid command-option ✘\033[m" >&2
    exit 1
  fi
fi

if ! command -v "$chosen_command" &> /dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mCommand-option '$1' not found ✘\033[m" >&2
  exit 1
fi

# Build release
OUTPUT_FILE=$(mktemp) || {
  echo -e "\033[35;1m!\033[m \033[91mError in creating temp file ✘\033[m" >&2
  exit 1
}

origin_url=$(git remote get-url origin 2>/dev/null)

if [[ ! -z "$origin_url" ]]; then
  origin_url="$(echo "$origin_url" | sed "s/\.git$//")"
else
  echo -e "\033[35;1m!\033[m \033[91mFailed to get remote (\033[37;1mOrigin\033[m) URL ✘\033[m" >&2
  exit 1
fi

COMMIT_LINK="$origin_url/commit"
RELEASES="$origin_url/releases/tag"
CHANGELOG="$origin_url/tree/master/CHANGELOG.md"
COMPARE_LINK="$origin_url/compare"

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
  local commits_list="$1"
  local prefix="$2"

  if [[ -n "$commits_list" ]]; then
    echo -e "\n## $prefix" >> $OUTPUT_FILE
    echo "$commits_list" >> $OUTPUT_FILE
  fi
}

latest_tag=$(git for-each-ref --count=1 --sort=-taggerdate --format '%(refname:short) %(taggerdate:short)' refs/tags)
if [[ -z "$latest_tag" ]]; then
  echo -e "\033[35;1m!\033[m \033[91mFailed to get the latest tag ✘\033[m" >&2
  exit 1
fi

tag=$(echo "$latest_tag" | awk '{print $1}')
date=$(echo "$latest_tag" | awk '{print $2}')

echo -e "# 🔖 Release [\`$tag\`]($RELEASES/$tag) ($date)" >> $OUTPUT_FILE

if [ -f "CHANGELOG.md" ]; then
  echo -e "\nSee the [⟲ CHANGELOG]($CHANGELOG) to see all the commits." >> $OUTPUT_FILE
fi

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
  released_commits=$(git log "$tag" --pretty=format:"%s")
else
  released_commits=$(git log "$previous_tag".."$tag" --pretty=format:"%s")
  echo -e "\nSee the [comparison ⟲ history]($COMPARE_LINK/$previous_tag...$tag) with the previous tag." >> $OUTPUT_FILE
fi

if [[ -z "$released_commits" ]]; then
  echo -e "\033[35;1m!\033[m \033[91mFailed to get released commits ✘\033[m" >&2
  exit 1
fi

echo -e "\n## 🔥 Main Changes\n\n-" >> $OUTPUT_FILE

while read -r subject; do
  formatted_subject=$(extract_prefix_and_message "$subject")
  prefix="${formatted_subject%%:*}"
  message="${formatted_subject#*:}"

  message="$(echo "${message:0:1}" | tr '[:lower:]' '[:upper:]')${message:1}"
  text=$(echo -e "\n- $message.")

  case $prefix in
    "feat") feat_commits+="$text";;
    "fix") fix_commits+="$text";;
    "chore") chore_commits+="$text";;
    "build") build_commits+="$text";;
    "style") style_commits+="$text";;
    "refactor") refactor_commits+="$text";;
    "test") test_commits+="$text";;
    "docs") docs_commits+="$text";;
    *) other_commits+="$text";;
  esac
done <<< "$released_commits"

append_commits_by_group "$build_commits" "🔨 Builds"
append_commits_by_group "$feat_commits" "✨ Features"
append_commits_by_group "$fix_commits" "🔧 Fixes"
append_commits_by_group "$refactor_commits" "♻️ Refactors"
append_commits_by_group "$test_commits" "🧪 Tests"
append_commits_by_group "$chore_commits" "📝 Chores"
append_commits_by_group "$docs_commits" "📄 Docs"
append_commits_by_group "$style_commits" "🎨 Styles"
append_commits_by_group "$other_commits" "📌 Others"

# Output
echo -e "\033[93mRelease.md \033[92mgenerated ✔\033[m" >&2

case $chosen_command in
  "cat")
    cat "$OUTPUT_FILE"
    echo -e "\033[33mCopy the content (Ctrl + Shift + C)\033[m" >&2
    ;;
  "gedit")
    echo -e "\033[33mCopy the content (Ctrl + A & Ctrl + C)\033[m" >&2
    gedit $OUTPUT_FILE
    ;;
  "nano")
    echo -e "\033[33mCopy the content (Ctrl + C)\033[m" >&2;
    nano $OUTPUT_FILE
    ;;
  "xclip")
    echo -e "\033[33mPaste the content (Ctrl + V)\033[m" >&2
    cat "$OUTPUT_FILE" | xclip -selection clipboard
    ;;
  *)
    echo -e "\033[35;1m!\033[m \033[91mInvalid command-option ✘\033[m" >&2
    rm $OUTPUT_FILE
    exit 1
    ;;
esac

rm $OUTPUT_FILE

exit 0
