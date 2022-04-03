#!/bin/bash

if [ $# -lt 1 ]; then
	echo -e "usage: $0 [--unmount] <root>"
	echo
	echo -e "where:"
	echo -e "\troot  path to rootfs where to mount pseudofiles"
	echo
	echo -e "Script mounts all pseudofs needed by system"
	echo -e "This needs to be done before chrooting to avoid errors"
	exit 1
fi

oper=mount
root=$1
if [ $1 == --unmount ]; then
	oper=unmount
	root=$2
fi

if [ $oper = mount ]; then
	mount --types proc /proc $root/proc

	mount --rbind /sys  $root/sys
	mount --rbind /dev  $root/dev
	mount --bind  /run  $root/run

	mount --make-rslave $root/sys
	mount --make-rslave $root/dev
	mount --make-slave  $root/run
else
	umount -R $root/sys
	umount -R $root/dev
	umount    $root/run
	umount    $root/proc
fi
