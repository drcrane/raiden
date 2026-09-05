#!/bin/sh
REL="v3.24"
ARCH="x86_64"
VER="3.0.8-r0"
FILE="apk-tools-static-${VER}.apk"
set -e
wget "https://dl-cdn.alpinelinux.org/alpine/${REL}/main/${ARCH}/${FILE}"
tar x -f apk-tools-static-${VER}.apk sbin/apk.static
rm "${FILE}"
mv sbin/apk.static .
rm -r sbin
