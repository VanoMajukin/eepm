download_jobs()
{
  for app in $apps; do
    local safe_app="${app//[^a-zA-Z0-9_]/_}"

    cat <<EOF
download_${safe_app}_p11:
  stage: download_test
  allow_failure: true
  image: alt:p11
  tags:
    - access
  before_script:
    - ./bin/epm -y repo set etersoft
    - ./bin/epm update
    - ./bin/epm -y install wget glibc-pthread file patool
    - ./bin/epm play --auto --ipfs kubo
  script:
    - bash ./ci/prepare_ipfs.sh ${app}
  artifacts:
    when: always
    expire_in: 7 days
    paths:
      - ipfs

EOF
  done
}

publish_job()
{
  cat <<'EOF'
publish_download_logs:
  stage: publish_download_logs
  image: alt:p11
  tags:
    - access
  when: always
  dependencies:
EOF
  for app in $apps; do
    local safe_app="${app//[^a-zA-Z0-9_]/_}"
    cat <<EOF
    - download_${safe_app}_p11
EOF
  done
  cat <<'EOF'
  before_script:
    - ./bin/epm -y repo set etersoft
    - ./bin/epm update
    - ./bin/epm -y install git rsync
  script:
    - echo "Publishing logs and IPFS DB"
    - ls -R ipfs
    - bash ./ci/push-ipfs-db.sh
  artifacts:
    when: always
    expire_in: 7 days
    paths:
      - ipfs

EOF
}
