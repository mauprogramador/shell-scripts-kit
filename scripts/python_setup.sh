#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler

# Help
readonly HELP_MANUAL="
Usage: pysetup [OPTION]

Setup a basic Python3 project for Poetry.
Add configuration and python files.

Options for Venv packages:
  -d             Add Docker files (Dockerfile and .dockerignore).
  -t             Add Tests files (tests/ and conftest).
  -v             Create Python3 Venv (no package installation).
  -h, --help     Display this help and exit.

Files added:
  Makefile, README.md, .gitignore, .env.example, .python-version,
  TODO, LICENSE, __init__.py, __main__.py, pyproject.toml.

Example:
  $ pysetup -v (Setup and create Venv)
"

if [[ "$1" == "--help" ]]; then
  echo -e "$HELP_MANUAL" >&2
  exit 0
fi

# Handle options
TEMPLATES="$(dirname "$0")/../templates"

while getopts ":hdtv" opt; do
  case $opt in
  d)
    cp $TEMPLATES/docker/Dockerfile Dockerfile &>/dev/null
    cp $TEMPLATES/docker/.dockerignore .dockerignore &>/dev/null
    logSuccess "Docker files" "added"
    ;;
  t)
    mkdir tests &>/dev/null
    cp $TEMPLATES/python/tests/__init__.py tests/__init__.py &>/dev/null
    cp $TEMPLATES/python/tests/conftest.py tests/conftest.py &>/dev/null
    logSuccess "Tests files" "added"
    ;;
  v)
    bash "$(dirname "$0")/../scripts/generate_venv.sh"
    ;;
  h)
    echo -e "$HELP_MANUAL" >&2
    exit 0
    ;;
  \?)
    invalidOption
    ;;
  :)
    logError "Option \033[93m-$OPTARG\033[91m requires an argument"
    echoHelp
    exit 1
    ;;
  esac
done

# Copy files
cp $TEMPLATES/Makefile Makefile &>/dev/null
cp $TEMPLATES/.gitignore .gitignore &>/dev/null
cp $TEMPLATES/README.md README.md &>/dev/null
cp $TEMPLATES/.python-version .python-version &>/dev/null
cp $TEMPLATES/.env.example .env.example &>/dev/null
cp $TEMPLATES/LICENSE LICENSE &>/dev/null
sed -i "s/CURRENT_YEAR/$(date '+%Y')/g" LICENSE &>/dev/null
echo "" >TODO &>/dev/null
logSuccess "Meta files" "added"

# Python files
mkdir src &>/dev/null

cp $TEMPLATES/python/src/__init__.py src/__init__.py &>/dev/null
sed -i "s/CURRENT_DATE/$(LC_ALL=en_US date '+%B %d, %Y')/g" src/__init__.py &>/dev/null
cp $TEMPLATES/python/src/__main__.py src/__main__.py &>/dev/null
cp $TEMPLATES/python/pyproject.toml pyproject.toml &>/dev/null
logSuccess "Python files" "added"

# Check if Git repo for pre-commit hook
if { git rev-parse --is-inside-work-tree >/dev/null 2>&1 || [ -d ".git" ]; }; then
  cp $TEMPLATES/pre-commit >.git/hooks/pre-commit &>/dev/null
  logSuccess "Git pre-commit hook" "added"
fi

# Output
logSuccess "Python setup" "complete"

exit 0
