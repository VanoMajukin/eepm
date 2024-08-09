#!/bin/sh

# [ "$1" != "--run" ] && echo "Enable unprivileged bubblewrap mode" && exit

. $(dirname $0)/common.sh

assure_root

[ "$(epm print info -e)" = "ALTLinux/Sisyphus" ] || fatal "Only ALTLinux Sisyphus is supported"

epm assure apt-repo-wks-kernel apt-https
epm update
update-kernel -f -t lks-wks