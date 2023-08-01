#!/bin/sh

if [ $# -lt 1 ]; then
	echo "usage: $0 <image> <dir>"
	echo
	echo "where"
	echo "	image     image to unpack"
	echo "	dir       dir where to unpack initrd"
	exit 1
fi

image=$(readlink -f $1)
cd $2
zcat $image | cpio -idmv
