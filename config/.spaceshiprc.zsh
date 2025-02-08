SPACESHIP_PROMPT_ORDER=(
  venv           # virtualenv section
  dir            # Current directory section
  host           # Hostname section
  git            # Git section (git_branch + git_status)
  node           # Node.js section
  python         # Python section
  docker         # Docker section
  docker_compose # Docker section
  gcloud         # Google Cloud Platform section
  exec_time      # Execution time
  line_sep       # Line break
  exit_code      # Exit code section
  sudo           # Sudo indicator
  char           # Prompt character
)
# Prompt
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=true
# Venv
SPACESHIP_VENV_PREFIX="("
SPACESHIP_VENV_SUFFIX=") "
SPACESHIP_VENV_GENERIC_NAMES=()
# Python
SPACESHIP_PYTHON_ASYNC=false
# Docker Compose
SPACESHIP_DOCKER_COMPOSE_SYMBOL="🐳 "
# Char
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "

