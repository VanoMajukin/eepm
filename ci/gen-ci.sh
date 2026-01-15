#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GEN_DIR="$SCRIPT_DIR/gen-ci.d"

. "$GEN_DIR/header.sh"
. "$GEN_DIR/download.sh"
. "$GEN_DIR/tests.sh"
. "$GEN_DIR/summary.sh"

# Get applications list
if [ -n "${CI_APPS:-}" ]; then
  apps="$CI_APPS"
else
  apps=$(./bin/epmp --short 2>/dev/null)
fi

# Get systems list
if [ -n "${CI_SYSTEMS:-}" ]; then
  systems="$CI_SYSTEMS"
else
  systems="alt:sisyphus debian:bookworm"
fi

# IPFS download stage switch
USE_DOWNLOAD=1
if [ -n "${CI_SKIP_DOWNLOAD:-}" ]; then
  USE_DOWNLOAD=0
fi

header

if [ "$USE_DOWNLOAD" -eq 1 ]; then
  download_jobs
  publish_job
fi

check_anchors
tests
summary
