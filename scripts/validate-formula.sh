#!/usr/bin/env bash
set -euo pipefail

# Lifecycle checks remove build-only dependencies: use an empty disposable prefix.
if [[ ${RESIZELINT_DISPOSABLE:-} != 1 ]]; then
  printf '%s\n' 'Set RESIZELINT_DISPOSABLE=1 only in a disposable Homebrew environment.' >&2
  exit 2
fi

source_repo=$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)
evidence=${1:?Usage: scripts/validate-formula.sh /absolute/evidence-directory}
mkdir -p "$evidence"
evidence=$(cd "$evidence" && pwd -P)
formula=audit/resizelint-candidate/resizelint
tap=audit/resizelint-candidate
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ENV_HINTS=1

run() {
  local label=$1 expected=$2 result
  shift 2
  printf '%s\n' "$*" > "$evidence/$label.command"
  set +e
  "$@" 2>&1 | tee "$evidence/$label.log"
  result=${PIPESTATUS[0]}
  set -e
  printf '%s\n' "$result" > "$evidence/$label.exit"
  if [[ $result != "$expected" ]]; then
    printf 'FAIL: %s returned %s (expected %s)\n' "$label" "$result" "$expected" >&2
    return 1
  fi
}

if brew list --formula resizelint >/dev/null 2>&1; then
  printf '%s\n' 'Refusing to replace an existing ResizeLint installation.' >&2
  exit 2
fi
if [[ -e $(brew --repository "$tap")/.git ]]; then
  printf '%s\n' 'Use a fresh prefix: the candidate tap already exists.' >&2
  exit 2
fi

run source-sha 0 git -C "$source_repo" rev-parse HEAD
run formula-hash 0 shasum -a 256 "$source_repo/Formula/resizelint.rb"
run brew-config 0 brew config
run platform 0 uname -sm
run tap 0 brew tap "$tap" "file://$source_repo"
tap_repo=$(brew --repository "$tap")
run tapped-sha 0 git -C "$tap_repo" rev-parse HEAD
run tapped-formula-hash 0 shasum -a 256 "$tap_repo/Formula/resizelint.rb"
run identical-formula 0 cmp "$source_repo/Formula/resizelint.rb" "$tap_repo/Formula/resizelint.rb"

run install 0 brew install --build-from-source --verbose "$formula"
run installed-info 0 brew info --json=v2 "$formula"
run compiler 0 "$(brew --prefix swift)/bin/swift" --version
run test 0 brew test --verbose "$formula"
run audit 0 brew audit --strict "$formula"
run style 0 brew style "$formula"
run linkage 0 brew linkage --test "$formula"
binary=$(brew --prefix "$formula")/bin/resizelint
if [[ $(uname -s) == Darwin ]]; then
  run libraries 0 otool -L "$binary"
  run load-commands 0 otool -l "$binary"
else
  run libraries 0 ldd "$binary"
  run load-commands 0 readelf -d "$binary"
  if grep -q 'not found' "$evidence/libraries.log"; then
    printf '%s\n' 'Unresolved runtime dependency.' >&2
    exit 1
  fi
fi
if grep -E '/private/tmp/|/tmp/[^ ]*resizelint|/home/linuxbrew/[^ ]*\.build/' "$evidence/load-commands.log"; then
  printf '%s\n' 'Binary still references its temporary build directory.' >&2
  exit 1
fi

consumer=$(mktemp -d "${TMPDIR:-/tmp}/resizelint-consumer.XXXXXX")
trap 'rm -rf "$consumer"' EXIT
printf '%s\n' 'import UIKit' 'func viewport() { let width = UIScreen.main.bounds.width }' > "$consumer/Broken.swift"
prefix_bin=$(brew --prefix)/bin
run outside-version 0 bash -c 'cd "$1"; exec env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH -u DYLD_FALLBACK_LIBRARY_PATH PATH="$2:/usr/bin:/bin" resizelint version' _ "$consumer" "$prefix_bin"
run outside-analysis 1 bash -c 'cd "$1"; exec env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH -u DYLD_FALLBACK_LIBRARY_PATH PATH="$2:/usr/bin:/bin" resizelint lint Broken.swift --format json' _ "$consumer" "$prefix_bin"

run reinstall 0 brew reinstall --build-from-source "$formula"
run after-reinstall-test 0 brew test "$formula"
run autoremove 0 brew autoremove
run after-cleanup-installed 0 brew list --versions
run after-cleanup-linkage 0 brew linkage --test "$formula"
run after-cleanup-test 0 brew test "$formula"
run after-cleanup-version 0 bash -c 'cd "$1"; exec env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH -u DYLD_FALLBACK_LIBRARY_PATH PATH="$2:/usr/bin:/bin" resizelint version' _ "$consumer" "$prefix_bin"
run after-cleanup-analysis 1 bash -c 'cd "$1"; exec env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH -u DYLD_FALLBACK_LIBRARY_PATH PATH="$2:/usr/bin:/bin" resizelint lint Broken.swift --format json' _ "$consumer" "$prefix_bin"
run uninstall 0 brew uninstall "$formula"
if [[ -e $(brew --prefix)/bin/resizelint ]]; then
  printf '%s\n' 'Homebrew executable remained after uninstall.' >&2
  exit 1
fi
printf '%s\n' 'PASS: source install, smoke tests, audit/style, linkage, reinstall, build-dependency cleanup and uninstall.'
