#!/usr/bin/env bash
set -euo pipefail

echo "Collecting CI results"

RESULTS_REPO_URL="https://gitlab.eterfund.ru/etersoft/epm-play-ci-results.git"
WORKDIR="results"

git clone "$RESULTS_REPO_URL" "$WORKDIR"
cd "$WORKDIR"

# git configuration
git config user.name "CI Bot"
git config user.email "ci@etersoft.ru"

# clean old data
rm -rf epm-results/*/epm-logs epm-results/*/epm-errors meta || true

# copy all results
rsync -a "$CI_PROJECT_DIR/epm-results/" epm-results/ || true

# ci info
mkdir -p meta
echo "$CI_PIPELINE_ID" > meta/pipeline-id
echo "$CI_COMMIT_SHA" > meta/commit-sha
date -u +%Y-%m-%dT%H:%M:%SZ > meta/timestamp

# commit
git add .
git commit -m "CI results: pipeline $CI_PIPELINE_ID" || {
    echo "Nothing to commit"
    exit 0
}

# push
git remote set-url origin "https://vanomj:${CI_PUSH_TOKEN}@gitlab.eterfund.ru/vanomj/epm-play-ci-results.git"
git push
