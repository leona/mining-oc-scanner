GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
GRAY=$'\033[2;37m'
RED=$'\033[0;31m'
NOCOLOR=$'\033[0m'

xecho() {
    color="$1"
    text="$2"
    echo "${color}${text}${NOCOLOR}"
}

cls() {
    printf "\033c"
}
