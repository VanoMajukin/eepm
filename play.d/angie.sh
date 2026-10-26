#!/bin/sh

PKGNAME=angie
SKIPREPACK=1
SUPPORTEDARCHES="x86_64 aarch64"
DESCRIPTION="ANGIE (a web server, that was forked from nginx) from the official site"
URL="https://angie.software/"
REPOURL="https://download.en.angie.software/angie"
LEGACY_REPOURL="https://download.angie.software/angie"
GPGKEY="https://angie.software/keys/angie-signing.gpg"
GPGKEYFILE="/etc/apt/trusted.gpg.d/angie-signing.gpg"

. $(dirname $0)/common.sh

reponame=$(epm print info --repo-name)
vendor=$(epm print info -s)
version=$(epm print info --base-version)

install_deb_key()
{
    local keyfile
    keyfile="$(mktemp)" || fatal
    eget --force -q -O "$keyfile" "$GPGKEY" || fatal
    if [ "$(id -u)" = 0 ] ; then
        install -m 0644 "$keyfile" "$GPGKEYFILE" || fatal
    else
        sudo install -m 0644 "$keyfile" "$GPGKEYFILE" || fatal
    fi
    rm -f "$keyfile"
}

# Migrate legacy Angie entries from sources.list to a named disabled repository.
# EPM can temporarily enable only the latter for angie/<package> installs.
case $(epm print info -g) in
    apt-rpm)
        epm --quiet repo remove "$LEGACY_REPOURL"
        epm --quiet repo remove "$REPOURL"
        ;;
esac

# Strict supported list
case $(epm print info -e) in
    Alpine/3.*)
        epm install --skip-installed ca-certificates
        epm repo addkey angie "https://angie.software/keys/angie-signing.rsa"
        epm repo add "$REPOURL/alpine/v$version/main"
        ;;
    AstraLinuxSE/1.7*|AstraLinuxSE/1.8*)
        epm repo addkey angie "https://angie.software/keys/angie-signing.gpg"
        epm repo add --disabled --name angie "deb $REPOURL/astra-se/$version/ unstable main"
        ;;
    ALTLinux/p10)
        epm repo addkey angie "https://angie.software/keys/angie-signing.gpg" "EB8EAF3D4EF1B1ECF34865A2617AB978CB849A76" "Angie (Signing Key) <devops@tech.wbsrv.ru>"
        epm repo add --disabled --name angie "rpm [angie] $REPOURL/altlinux/10/ x86_64 main"
        ;;
    ALTLinux/p11|ALTLinux/Sisyphus)
        epm repo addkey angie "https://angie.software/keys/angie-signing.gpg" "EB8EAF3D4EF1B1ECF34865A2617AB978CB849A76" "Angie (Signing Key) <devops@tech.wbsrv.ru>"
        epm repo add --disabled --name angie "rpm [angie] $REPOURL/altlinux/11/ x86_64 main"
        ;;
    ALTLinux/c10f*)
        epm repo addkey angie "https://angie.software/keys/angie-signing.gpg" "EB8EAF3D4EF1B1ECF34865A2617AB978CB849A76" "Angie (Signing Key) <devops@tech.wbsrv.ru>"
        epm repo add --disabled --name angie "rpm [angie] $REPOURL/altlinux-sp/10/ x86_64 main"
        ;;
    ALTLinux/c9f*|ALTLinux/c8*)
        epm repo addkey angie "https://angie.software/keys/angie-signing.gpg" "EB8EAF3D4EF1B1ECF34865A2617AB978CB849A76" "Angie (Signing Key) <devops@tech.wbsrv.ru>"
        epm repo add --disabled --name angie "rpm [angie] $REPOURL/altlinux-sp/8/ x86_64 main"
        ;;
    AlmaLinux/*)
        epm repo addkey angie 'https://download.angie.software/angie/centos/$releasever/' "https://angie.software/keys/angie-signing.gpg" "Angie repo"
        #epm repo add 'https://download.angie.software/angie/centos/$releasever/'
        ;;
    CentOS/8|CentOS/9|MSVSphere/9)
        epm repo addkey angie 'https://download.angie.software/angie/centos/$releasever/' "https://angie.software/keys/angie-signing.gpg" "Angie repo"
        #epm repo add 'https://download.angie.software/angie/centos/$releasever/'
        ;;
    Fedora/*)
        epm repo addkey angie "$REPOURL/fedora/$version/" "https://angie.software/keys/angie-signing.gpg.asc" "Angie repo"
        ;;
    Debian/*)
        epm install --skip-installed adduser ca-certificates lsb-release
        install_deb_key
        epm repo add --disabled --name angie "deb [signed-by=$GPGKEYFILE] $REPOURL/debian/$version/ $reponame main"
        ;;
    Oracle/*)
        epm repo addkey angie 'https://download.angie.software/angie/oracle/$releasever/' "https://angie.software/keys/angie-signing.gpg" "Angie repo"
        #epm repo add 'https://download.angie.software/angie/oracle/$releasever/'
        ;;
    RedOS/7*|RedOS/8*)
        epm repo addkey angie 'https://download.angie.software/angie/redos/$releasever/' "https://angie.software/keys/angie-signing.gpg" "Angie repo"
        #epm repo add "https://download.angie.software/angie/redos/7/"
        ;;
    ROSA/*)
        epm repo addkey angie "https://download.angie.software/angie/rosa/$releasever/" "https://angie.software/keys/angie-signing.gpg" "Angie repo"
        #epm repo add "https://download.angie.software/angie/redos/8/"
        ;;
    RockyLinux/8|RockyLinux/9)
        epm repo addkey angie 'https://download.angie.software/angie/rocky/$releasever/' "https://angie.software/keys/angie-signing.gpg" "Angie repo"
        #epm repo add 'https://download.angie.software/angie/rocky/$releasever/'
        ;;
    Ubuntu/*)
        epm install --skip-installed adduser ca-certificates lsb-release
        install_deb_key
        epm repo add --disabled --name angie "deb [signed-by=$GPGKEYFILE] $REPOURL/ubuntu/$version/ $reponame main"
        ;;
    *)
        fatal "Unsupported distro $(epm print info -e). Ask application vendor for a support."
        ;;
esac

case $(epm print info -g) in
    apt-rpm|apt-dpkg)
        epm install angie/$PKGNAME || exit
        ;;
    *)
        epm update
        epm install $PKGNAME || exit
        ;;
esac

cat <<EOF

Note:
You can use serv command for start Angie service:
    # serv angie start
To make sure Angie starts on server reboot, run:
    # serv angie on
Also you can install an addional modules:
    # epm install angie-module-<module>

Angie repository provides following dynamic module packages:
  angie-module-auth-spnego
  angie-module-brotli
  angie-module-dav-ext
  angie-module-geoip2
  angie-module-headers-more
  angie-module-image-filter
  angie-module-ndk
  angie-module-njs
  angie-module-perl
  angie-module-rtmp
  angie-module-set-misc
  angie-module-xslt
EOF
