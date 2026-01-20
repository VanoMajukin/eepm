#!/usr/bin/env bash
set -euo pipefail

echo "Collecting CI results"

RESULTS_REPO_URL="https://gitlab.eterfund.ru/etersoft/epm-play-ci-results.git"
WORKDIR="results"
RESULTS_DIR="${CI_RESULTS_DIR:-epm-results}"
RESULTS_LABEL="${CI_RESULTS_LABEL:-custom}"

META_DIR="meta"
if [ "$RESULTS_DIR" != "epm-results" ]; then
  META_DIR="${RESULTS_DIR}/meta"
fi

git clone "$RESULTS_REPO_URL" "$WORKDIR"
cd "$WORKDIR"

# git configuration
git config user.name "CI Bot"
git config user.email "ci@etersoft.ru"

# clean old data
rm -rf "${RESULTS_DIR}"/*/epm-logs "${RESULTS_DIR}"/*/epm-errors "$META_DIR" || true

# copy all results
mkdir -p "$RESULTS_DIR"
rsync -a "$CI_PROJECT_DIR/epm-results/" "${RESULTS_DIR}/" || true

# ci info
mkdir -p "$META_DIR"
echo "$CI_PIPELINE_ID" > "${META_DIR}/pipeline-id"
echo "$CI_COMMIT_SHA" > "${META_DIR}/commit-sha"
date -u +%Y-%m-%dT%H:%M:%SZ > "${META_DIR}/timestamp"

# commit
git add .
git commit -m "CI results (${RESULTS_LABEL}): pipeline $CI_PIPELINE_ID" || {
    echo "Nothing to commit"
    exit 0
}

# push
git remote set-url origin "https://vanomj:${CI_PUSH_TOKEN}@gitlab.eterfund.ru/vanomj/epm-play-ci-results.git"
git push
