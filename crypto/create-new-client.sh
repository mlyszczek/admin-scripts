#!/bin/bash

if [ $# -lt 1 ]; then
	echo "usage: $0 <name>"
	echo "       $0 <name> <dev> <pass>"
	echo "where"
	echo "name:   hostname of machine for which key is generated"
	echo "pass:   use custom pass instead of generating random key"
	echo "dev:    create luks on specified dev, header will be attached to this dev"
	exit 1
fi

mkdir $1

if [ "$2" ]; then
	fdisk -l $2
	echo "ARE YOU SURE YOU WANNA DESTROY THAT DISK/PARTITION?! ARE YOU?"
	echo "TYPE CAPITAL 'YES' IF YOU ARE"
	read choice
	if [ x$choice != xYES ]; then
		echo "you're not sure, that's ok, better safe than sorry"
		echo "double check and retry"
		exit 0
	fi
	printf "%s" "$3" > $1/keyfile
	cryptsetup luksFormat -c aes-xts-plain64 -s 256 -h sha256 -d $1/keyfile $2
else
	tmp=$(mktemp)
	truncate -s1 $tmp
	dd if=/dev/urandom of=$1/keyfile bs=128 count=1
	cryptsetup luksFormat -c aes-xts-plain64 -s 256 -h sha256 -d $1/keyfile \
			--header $1/header $tmp << EOF
YES${comment_confirm_creation_of_missing_header_file}
EOF
	rm $tmp
fi

cat << EOF > $1/disks
# /path/to/disk   mapper-friendly-name
# path to disk can be path to /dev/disk/by-id/* or similar
# friendly name is a name that disk will be seen in /dev/mapper
# with friendly name you can call standard mount program
EOF
