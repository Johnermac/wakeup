#!/bin/bash

imlazy(){
  FRAMES=(
  "        Z
    (-_-) "

  "        ZZ
    (-_-) "

  "        ZZZ
    (-_-) "

  "   
    (O_O) !!
  Time to wake up!
  
  "
  )

  for frame in "${FRAMES[@]}"; do
    clear
    echo "$frame"
    sleep 1
  done

  echo -e "${BOLD}${CYAN}🔍 Scanning in:${RESET} $FOLDER"
  echo

}

set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 <folder_path> <language>"
  exit 1
fi



RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

FOLDER=$1
LANGUAGE=$2
# CONTEXT_LINES=$3

CHECK_FILE="checks/${LANGUAGE}.txt"

declare -a CHECKS
declare -A FILE_EXTENSIONS=( ["py"]="py" ["go"]="go" ["js"]="js" ["rb"]="rb" ["php"]="php" ["docker"]="yml" )


parameters_ready() {
  
  if [[ ! -d "$FOLDER" ]]; then
    echo "❌ Folder does not exist: $FOLDER"
    exit 1
  fi  

  EXT="${FILE_EXTENSIONS[$LANGUAGE]}"
  if [[ -z "$EXT" ]]; then
    echo "❌ Unsupported language: $LANGUAGE"
    exit 1
  fi

  # Load patterns from check file
  mapfile -t CHECKS < "$CHECK_FILE"  

}

run_checks() {
  local label=$1
  shift
  local patterns=("$@")
  declare -a RESULTS

  echo -e "${BOLD}🔸 $label${RESET}"
  echo

  for dep in "${patterns[@]}"; do
    while IFS=: read -r file line content; do
      [[ -z "$file" || -z "$line" ]] && continue
      RESULTS+=("$file:$line: $dep")
    done < <(grep -rn --include="*.${EXT}" \
      --exclude-dir={.git,__pycache__} \
      --exclude="*-semgrep*" \
      --exclude="*-depscan*" \
      --exclude="*-dangerous*" \
      "$dep" "$FOLDER")
  done

  if [[ ${#RESULTS[@]} -eq 0 ]]; then
    echo -e "${RED}❌ No matches found.${RESET}"
    return
  fi

  printf "%s\n" "${RESULTS[@]}" | \
  fzf --ansi --no-sort --reverse --prompt="Select finding: " \
    --preview='f=$(cut -d: -f1 <<< {}); l=$(cut -d: -f2 <<< {}); [[ -f "$f" ]] && batcat --color=always --style=numbers --highlight-line $l "$f"' \
    --preview-window=up:wrap:80% \
    --bind 'enter:execute-silent(f=$(cut -d: -f1 <<< {}); l=$(cut -d: -f2 <<< {}); code -g "$f:$l")'
}

parameters_ready
imlazy
run_checks "${LANGUAGE^} Checks" "${CHECKS[@]}"


