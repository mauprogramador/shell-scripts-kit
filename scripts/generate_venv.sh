#!/bin/bash

if ! source "$(dirname "$0")/../utils/functions.sh" &>/dev/null; then
  echo -e "\033[35;1m!\033[m \033[91mFailed import ✘\033[m" >&2
  exit 1
fi

signalHandler

# Help
readonly HELP_MANUAL="
Usage: venv [OPTION]

Creates a new Python Venv (.venv) using the Venv module to install and use packages and libraries.
It will use the Python3 version found and can install dependencies using Pip and Poetry.
It updates Pip and installs the Poetry package by default.
It only creates the Venv (no package installation) by default if no option is provided.

Options for Venv packages:
  -r             Create Venv and install dependencies with Pip from requirements.txt.
  -p             Create Venv and install dependencies with Poetry from pyproject.toml and poetry.lock.
  -v             Python3 version to use in Venv.
  -h, --help     Display this help and exit.

Commands used when installing dependencies:
  Pip            pip3 install -r requirements.txt
  Poetry         poetry install --no-root

Example:
  $ venv -v 11 (Create a Venv with no package for Python3.11)

Docs:
  Venv: https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/
  Requirements: https://pip.pypa.io/en/latest/user_guide/#requirements-files
  Poetry: https://python-poetry.org/docs/
  Versions: https://www.python.org/doc/versions/
"

if [[ "$1" == "--help" ]]; then
  echo -e "$HELP_MANUAL" >&2
  exit 0
fi

# Check if allowed option
dependencies_build="none"
python3_version=""

# e.g. 09, 10, 11, 12
VERSION_PATTERN="^[0-9]{1,2}$"

while getopts ":hrpv:" opt; do
  case $opt in
  r)
    dependencies_build="pip"
    ;;
  p)
    dependencies_build="poetry"
    ;;
  v)
    if [[ ! "$OPTARG" =~ $VERSION_PATTERN ]]; then
      logError "Invalid Python3 version \033[93m3.$OPTARG\033[91m"
      exit 1
    elif command -v "python3.$OPTARG" &>/dev/null; then
      python3_version="$OPTARG"
      logSuccess "$(python3."$OPTARG" -V)" "installed"
    else
      echo $OPTARG
      exitError "No \033[93mPython3.$OPTARG\033[91m installation found"
      exit 1
    fi
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

# Check for existing Venv
VENV_DIRECTORIES=(".venv" "venv" ".Venv" "Venv")

for venv_dir in "${VENV_DIRECTORIES[@]}"; do
  if [ -d "$venv_dir" ]; then
    logError "Python Venv already exists ($venv_dir)"
    default_answer="y"

    echo -ne "Would you like to replace it with a new one? $YESNO: "
    read ANSWER

    if [[ -z "$ANSWER" ]]; then
      ANSWER="$default_answer"
    fi

    if handleAnswer; then
      rm -rf "$venv_dir"

      if [ $? -ne 0 ]; then
        exitError "Failed to remove existing Venv ($venv_dir)"
      fi

      logError "Existing Venv removed ($venv_dir)"
    fi
    break
  fi
done

# If Python3 version is not provided
if [ -z "$python3_version" ]; then
  logError "No Python3 version provided"

  # Checking if Python3 is installed
  if ! command -v python3 &>/dev/null; then
    logError "No Python3 installations found"
    furtherInfo "https://docs.python-guide.org/starting/install3/linux/"
  fi

  # Find all installed Python3 versions
  EXECUTABLE_PATH="/usr/bin/python3*"
  found_python3=()

  # e.g. python3.10, python3.11
  PYTHON3_PATTERN="python3\.[0-9]*$"

  for python3 in $EXECUTABLE_PATH; do
    version=$(echo "$python3" | grep -Eo $PYTHON3_PATTERN | sort -V | uniq)
    if command -v "$version" &>/dev/null && [[ -x "$python3" ]]; then
      found_python3+=("${version^}")
    fi
  done

  # If no Python3 versions are found
  if [[ ${#found_python3[@]} -eq 0 ]]; then
    logError "No Python3 installations found"
    furtherInfo "https://docs.python-guide.org/starting/install3/linux/"
  fi

  # Select version menu
  echo "Installed Python3 versions found:" >&2
  PS3="Select a Python3 version: "

  # e.g. 09, 10, 11, 12
  VERSION_PATTERN="[0-9]*$"

  select python3 in "${found_python3[@]}"; do
    if [[ -n "$python3" ]]; then
      python3_version=$(echo "$python3" | grep -Eo $VERSION_PATTERN)
      break
    else
      logError "Invalid option \033[93m$REPLY\033[91m"
    fi
  done

  logSuccess "$(python3."$python3_version" -V)" "selected"
fi

# echo -e "\033[93mWARNING:\033[m This application was built on \033[37;1mPython3.11.0rc1\033[m, so some unexpected errors may occur when using a different version."
# echo -ne "\033[35;1m?\033[m Would you like to continue with \033[37;1m$(python3."$version" -V)\033[m? [\033[32my\033[m/\033[31mn\033[m]: "

# Check if Pip is installed
if command -v pip &>/dev/null; then
  logSuccess "Pip $(pip --version | awk '{print $2}')" "installed"
else
  logError "No Pip installation found"
  furtherInfo "https://pip.pypa.io/en/stable/"
fi

# Check if Venv is installed
if python3 -c 'import venv' &>/dev/null; then
  logSuccess "Venv Module" "installed"
else
  logError -e "No Venv Module installation found"
  furtherInfo "https://docs.python.org/3/library/venv.html"
fi

# Create and handle Venv
echo -e "Creating \033[37;1mPython Virtual Environment\033[m..." >&2
VENV_DIR=".venv"
python3."$python3_version" -m venv $VENV_DIR

removeVenv() {
  rm -rf "$VENV_DIR"

  if [ $? -ne 0 ]; then
    exitError "Failed to remove existing Venv ($VENV_DIR)"
  fi

  exitError "Existing Venv removed ($VENV_DIR)"
}

if [ $? -ne 0 ]; then
  logError "Failed to create Python Venv"

  if [ -d "$VENV_DIR" ]; then
    removeVenv
  fi

  exit 1
fi

# Activate created Venv
logSuccess "Virtual Environment $VENV_NAME" "created"
source .venv/bin/activate

# Upgrading Pip
pip install --upgrade pip
logSuccess "Pip" "upgraded"

# Install Poetry
pip3 install poetry
logSuccess "Poetry package" "installed"

# Install requirements.txt packages
REQUIREMENTS_FILE="requirements.txt"

if [[ "$dependencies_build" == "pip" ]]; then
  requirements_path=""

  if [[ -f "$REQUIREMENTS_FILE" ]]; then
    requirements_path="$REQUIREMENTS_FILE"
  else
    requirements_path=$(find . -maxdepth 2 -name "$REQUIREMENTS_FILE")
  fi

  if [[ -z "$requirements_path" ]]; then
    exitError "No $REQUIREMENTS_FILE file found"
  fi

  pip3 install -r "$requirements_path"

  if [[ $? -ne 0 ]]; then
    logError "Failed to install packages from $REQUIREMENTS_FILE"
    removeVenv
  fi

  logSuccess "$REQUIREMENTS_FILE packages" "installed"
fi

# Install poetry packages
PYPROJECT_FILE="pyproject.toml"

if [[ "$dependencies_build" == "poetry" ]]; then

  if ! [[ -f "$PYPROJECT_FILE" ]]; then
    exitError "No $PYPROJECT_FILE file found"
  fi

  poetry install --no-root

  if [[ $? -ne 0 ]]; then
    logError "Failed to install packages from $PYPROJECT_FILE"
    removeVenv
  fi

  logSuccess "$PYPROJECT_FILE packages" "installed"
fi

# Output
deactivate
logSuccess "$(python3."$python3_version" -V) Venv $VENV_NAME" "created"

exit 0
