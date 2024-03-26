#/usr/bin/env bash -x

VERSION="0.0.1"
MODFILE="mods/link_${VERSION}.zip"

FACTORIO_CLIENT_MOD_DIR="/mnt/c/Users/${USER}/AppData/Roaming/Factorio/mods/"

rm $MODFILE
7za a $MODFILE factorio-link
cp -fv $MODFILE $FACTORIO_CLIENT_MOD_DIR
