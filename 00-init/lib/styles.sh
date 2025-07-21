# lib/colors.sh
# Source this in your scripts: . ./lib/styles.sh

# --- Styles ---
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"
UNDERLINE="\033[4m"
INVERSE="\033[7m"

# --- Standard Foreground Colors ---
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

# --- Bright Foreground Colors ---
BRIGHT_BLACK="\033[90m"
BRIGHT_RED="\033[91m"
BRIGHT_GREEN="\033[92m"
BRIGHT_YELLOW="\033[93m"
BRIGHT_BLUE="\033[94m"
BRIGHT_MAGENTA="\033[95m"
BRIGHT_CYAN="\033[96m"
BRIGHT_WHITE="\033[97m"

# --- Background Colors ---
BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_MAGENTA="\033[45m"
BG_CYAN="\033[46m"
BG_WHITE="\033[47m"

# --- Bright Background Colors ---
BG_BRIGHT_BLACK="\033[100m"
BG_BRIGHT_RED="\033[101m"
BG_BRIGHT_GREEN="\033[102m"
BG_BRIGHT_YELLOW="\033[103m"
BG_BRIGHT_BLUE="\033[104m"
BG_BRIGHT_MAGENTA="\033[105m"
BG_BRIGHT_CYAN="\033[106m"
BG_BRIGHT_WHITE="\033[107m"

# --- Symbols (UTF-8 Safe) ---
CHECK="${GREEN}✔${RESET}"
CROSS="${RED}✗${RESET}"
INFO="${CYAN}➤${RESET}"
WARN="${YELLOW}⚠${RESET}"
QUESTION="${CYAN}❓${RESET}"
ARROW="${CYAN}➔${RESET}"
SPARKLE="${YELLOW}✨${RESET}"
DOT="${BLUE}•${RESET}"
STAR="${YELLOW}★${RESET}"
BULLET="${MAGENTA}‣${RESET}"

# --- Block Characters (for progress bars, etc) ---
BLOCK_FULL="█"
BLOCK_THREE_QUARTERS="▓"
BLOCK_HALF="▒"
BLOCK_QUARTER="░"

# --- Functions for colored output (bash & zsh compatible) ---
color_echo() {
  # Usage: color_echo "$GREEN" "Message"
  local color="$1"
  shift
  printf "%b%b%b\n" "$color" "$*" "$RESET"
}

function section() {
  echo -e "\n${BOLD}${CYAN}=== $1 ===${RESET}"
}
function prompt() {
  echo -en "${BOLD}${YELLOW}$1${RESET} "
}
function success() {
  echo -e "${CHECK} $1"
}
function error() {
  echo -e "${CROSS} $1" >&2
}
function info() {
  echo -e "${INFO} $1"
}

# Example: color_echo "$BOLD$GREEN" "Success!"

# --- Usage Examples as Comments ---

# color_echo "$BOLD$CYAN" "A Bold Cyan Heading"
# echo -e "${WARN} This is a warning!"
# echo -e "${CHECK} Operation successful"
# echo -e "${BOLD}${RED}Error:${RESET} Something failed"
# echo -e "${BG_YELLOW}${BLACK} This is black on yellow ${RESET}"

# --- End of lib/colors.sh ---
