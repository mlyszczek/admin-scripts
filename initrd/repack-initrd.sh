#!/bin/sh

if [ $# -lt 1 ]; then
	echo "usage: $0 <dir> <image>"
	echo
	echo "where"
	echo "	dir       dir where unpacked initrd is"
	echo "	image     destination dir for new initrd image"
	exit 1
fi

image=$(readlink -f $2)
cd $1
find . | cpio -o --format=newc --quiet | gzip -9 > $image
