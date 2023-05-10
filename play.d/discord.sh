#!/bin/sh

PKGNAME=discord
SUPPORTEDARCHES="x86_64"
VERSION="$2"
DESCRIPTION="Discord from the official site"

. $(dirname $0)/common.sh

if [ "$VERSION" != "*" ] ; then
    PKGURL="https://dl.discordapp.net/apps/linux/$VERSION/discord-$VERSION.deb"
else
    # workaround against curl can't get filename: https://github.com/curl/curl/issues/8461
    PKGURL="$(eget --get-real-url "https://discord.com/api/download?platform=linux&format=deb")"
fi

epm install "$PKGURL"
