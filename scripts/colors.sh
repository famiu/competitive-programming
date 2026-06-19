# ANSI color codes and print helpers.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
#
# Respects NO_COLOR (https://no-color.org/).
# Auto-disables when neither stdout nor stderr is a terminal.

if [[ -n "${NO_COLOR:-}" ]] || { [[ ! -t 1 ]] && [[ ! -t 2 ]]; }; then
    BOLD=''; DIM=''; RESET=''
    RED=''; GREEN=''; YELLOW=''; CYAN=''
else
    BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
    RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; CYAN='\033[36m'
fi

# Test status labels (stdout)
status_pass() { printf "${GREEN}PASS${RESET}    %s\n" "$*"; }
status_fail() { printf "${RED}FAIL${RESET}    %s\n" "$*"; }
status_tle()  { printf "${YELLOW}TLE${RESET}     %s\n" "$*"; }
status_re()   { printf "${RED}RE${RESET}      %s\n" "$*"; }

# Test status labels with prefix (e.g. counter "[3/4]")
status_pass_p() { printf "%s ${GREEN}PASS${RESET}    %s\n" "$1" "$2"; }
status_fail_p() { printf "%s ${RED}FAIL${RESET}    %s\n" "$1" "$2"; }
status_tle_p()  { printf "%s ${YELLOW}TLE${RESET}     %s\n" "$1" "$2"; }
status_re_p()   { printf "%s ${RED}RE${RESET}      %s\n" "$1" "$2"; }

# Messages (stderr)
error() { printf "${BOLD}${RED}error:${RESET} %s\n" "$*" >&2; }
warn()  { printf "${YELLOW}warning:${RESET} %s\n" "$*" >&2; }

# Info / dim (stdout)
info() { printf "${CYAN}%s${RESET}\n" "$*"; }
dim()  { printf "${DIM}%s${RESET}\n" "$*"; }

# Section headers for diff previews etc. (stderr)
section() { printf "${CYAN}%s${RESET}\n" "$*" >&2; }

# Separator (stdout)
separator() { printf "${DIM}────────────────────────────────────${RESET}\n"; }

# Success indicators (stdout)
success()     { printf "${GREEN}%s${RESET}\n" "$*"; }
success_dim() { printf "${DIM}${GREEN}%s${RESET}\n" "$*"; }
