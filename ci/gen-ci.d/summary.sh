summary()
{
  cat <<'EOF'
summary_ci:
  stage: summary
  image: alt:p11
  tags:
    - access
  when: always
  before_script:
    - ./bin/epm -y repo set etersoft
    - ./bin/epm update
    - ./bin/epm -y install git rsync
  script:
    - bash ./ci/push-results-ci.sh

EOF
}
