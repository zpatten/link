#/usr/bin/env bash
set -x

VERSION="0.0.1"
MODFILE="mods/link_${VERSION}.zip"

rm $MODFILE
7za a $MODFILE factorio-link
