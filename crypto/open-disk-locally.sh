#!/bin/sh

if [ $# -ne 2 ]; then
	echo "usage: $0 <hostname> <dev>"
	exit 1
fi

keyfile=$1/keyfile
header=$1/header

if [ -s $header ]; then
	cryptsetup luksOpen --key-file $keyfile --header $header $2 local-$1
else
	cryptsetup luksOpen --key-file $keyfile $2 local-$1
fi
