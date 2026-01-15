#!/usr/bin/env bash
set -euo pipefail

# detect OS
ID="$(./bin/epm print info -d)"
VERSION_ID="$(./bin/epm print info -v)"
CI_SYSTEM_ID="$ID-$VERSION_ID"

# args
APP="$1"

# vars
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT_DIR="${CI_PROJECT_DIR:-$REPO_ROOT}"
RESULTS_ROOT="$PROJECT_DIR/epm-results/$CI_SYSTEM_ID"

PLAY_DIR="$RESULTS_ROOT/epm-play-versions"
ERR_DIR="$RESULTS_ROOT/epm-errors"
LOG_DIR="$RESULTS_ROOT/epm-logs"
REQ_DIR="$RESULTS_ROOT/epm-requires"

mkdir -p "$PLAY_DIR" "$ERR_DIR" "$LOG_DIR" "$REQ_DIR"

cd "$REPO_ROOT/bin"

# IPFS
if [ -n "${CI_SKIP_IPFS_UPDATE:-}" ]; then
  export EPM_IPFS_DB_UPDATE_SKIPPING=1
fi
export EGET_IPFS_API=/ip4/91.232.225.49/tcp/5001

echo "Installing $APP"

set +e
./epm play --latest --auto --ipfs "$APP" 2>&1 | tee "$LOG_DIR/$APP.log"
rc=${PIPESTATUS[0]}
set -e

# result
if [ "$rc" -eq 0 ]; then
  echo "V $APP: PASS"

  package_name="$(./epm play --package-name "$APP")"

  ./epm print version for package "$package_name" \
    >"$PLAY_DIR/$package_name" \
    2>"$ERR_DIR/$package_name" || true

  ./epm req "$package_name" >"$REQ_DIR/$package_name" 2>&1 || true
else
  echo "X $APP: FAIL"
  mv -vf "$LOG_DIR/$APP.log" "$ERR_DIR/$APP.log"
fi

# cleanup empty error files and dir
if [ -d "$ERR_DIR" ]; then
  find "$ERR_DIR" -type f -size 0 -delete
  rmdir "$ERR_DIR" 2>/dev/null || true
fi

echo "Exit code: $rc"
exit "$rc"
