#!/usr/bin/env bash
set -euo pipefail

echo "=== Publishing IPFS DB ==="

# repo vars
IPFS_REPO_URL="https://gitlab.eterfund.ru/etersoft/epm-play-ci-results.git"
WORKDIR="ipfs-results"

# check
if [ ! -f "ipfs/eget-ipfs-db.txt" ]; then
  echo "ERROR: ipfs/eget-ipfs-db.txt not found"
  exit 1
fi

# clone repo
git clone "$IPFS_REPO_URL" "$WORKDIR"
cd "$WORKDIR"

# git setup
git config user.name "CI Bot"
git config user.email "ci@etersoft.ru"

# clean old data
rm -rf ipfs/logs/ ipfs/errors/ || true

# prepare dirs
mkdir -p ipfs/logs ipfs/errors ipfs/meta

# replace DB and logs
cp -f ../ipfs/eget-ipfs-db.txt ipfs/eget-ipfs-db.txt
rsync -a ../ipfs/logs/ ipfs/logs/ || true
rsync -a ../ipfs/errors/ ipfs/errors/ || true

# meta info
echo "$CI_PIPELINE_ID" > ipfs/meta/pipeline-id
echo "$CI_COMMIT_SHA"  > ipfs/meta/commit-sha
date -u +%Y-%m-%dT%H:%M:%SZ > ipfs/meta/timestamp

# commit
git add ipfs

git commit -m "IPFS DB update (pipeline $CI_PIPELINE_ID)" || {
  echo "Nothing to commit"
  exit 0
}

# push via PAT
git remote set-url origin \
  "https://vanomj:${CI_PUSH_TOKEN}@gitlab.eterfund.ru/vanomj/epm-play-ci-results.git"

git push

echo "=== IPFS DB and download log's published ==="
