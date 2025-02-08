#!/bin/bash

trap "echo -e '\033[35;1m!\033[m \033[91mGot an interruption ✘\033[m' ; exit 1" SIGINT

OUTPUT_FILE="CHANGELOG.md"
echo "# Changelog" > $OUTPUT_FILE

origin_url=$(git remote get-url origin 2>/dev/null)

if [[ ! -z "$origin_url" ]]; then
  origin_url="$(echo "$origin_url" | sed "s/\.git$//")"
else
  echo -e "\033[m-\033[91m Failed to get remote (\033[37;1mOrigin\033[m) URL ✘\033[m" >&2
  exit 1
fi

COMMIT_LINK="$origin_url/commit"
RELEASES="$origin_url/releases/tag"

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
    echo -e "\n### $prefix" >> $OUTPUT_FILE
    echo "$commits_list" >> $OUTPUT_FILE
  fi
}

unreleased_commits=$(git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"%h %H %cs %s")

if [[ -n "$unreleased_commits" ]]; then
  echo -e "\n## 🔥 Latest Unreleased" >> $OUTPUT_FILE

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
    text=$(echo -e "\n- $message. [#$short_hash]($COMMIT_LINK/$commit_hash) ($short_date)")

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
  done <<< "$unreleased_commits"

  append_commits_by_group "$build_commits" "🔨 Builds"
  append_commits_by_group "$feat_commits" "✨ Features"
  append_commits_by_group "$fix_commits" "🔧 Fixes"
  append_commits_by_group "$refactor_commits" "♻️ Refactors"
  append_commits_by_group "$test_commits" "🧪 Tests"
  append_commits_by_group "$chore_commits" "📝 Chores"
  append_commits_by_group "$docs_commits" "📄 Docs"
  append_commits_by_group "$style_commits" "🎨 Styles"
  append_commits_by_group "$other_commits" "📌 Others"
fi

tags=$(git for-each-ref --sort=-taggerdate --format '%(refname:short) %(taggerdate:short)' refs/tags)

while read -r tag tag_date; do
  echo -e "\n## 🔖 Release [\`$tag\`]($RELEASES/$tag) ($tag_date)" >> $OUTPUT_FILE

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
  fi

  while read -r short_hash commit_hash short_date subject; do
    formatted_subject=$(extract_prefix_and_message "$subject")
    prefix="${formatted_subject%%:*}"
    message="${formatted_subject#*:}"

    message="$(echo "${message:0:1}" | tr '[:lower:]' '[:upper:]')${message:1}"
    text=$(echo -e "\n- $message. [#$short_hash]($COMMIT_LINK/$commit_hash) ($short_date)")

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

done <<< "$tags"

echo -e "\033[93m$OUTPUT_FILE \033[92mgenerated ✔\033[m" >&2
