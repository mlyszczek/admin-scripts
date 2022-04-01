#!/bin/bash

if [ $# -ne 1 ]; then
	echo "usage: $0 <name>"
	echo "where"
	echo "name:   hostname of machine for which key is generated"
	exit 1
fi

tmp=$(mktemp)
truncate -s1 $tmp
mkdir $1
dd if=/dev/urandom of=$1/keyfile bs=128 count=1
cryptsetup luksFormat -c aes-xts-plain64 -s 256 -h sha256 -d $1/keyfile \
		--header $1/header $tmp << EOF
#YES${comment_confirm_creation_of_missing_header_file}
#EOF
rm $tmp
cat << EOF > $1/disks
# /path/to/disk   mapper-friendly-name
# path to disk can be path to /dev/disk/by-id/* or similar
# friendly name is a name that disk will be seen in /dev/mapper
# with friendly name you can call standard mount program
EOF
