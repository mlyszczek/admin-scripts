#!/bin/sh


## ==========================================================================
#              / __/__  __ ____   _____ / /_ (_)____   ____   _____
#             / /_ / / / // __ \ / ___// __// // __ \ / __ \ / ___/
#            / __// /_/ // / / // /__ / /_ / // /_/ // / / /(__  )
#           /_/   \__,_//_/ /_/ \___/ \__//_/ \____//_/ /_//____/
## ==========================================================================

confirm()
{
	d=${1}
	echo ${2} ${d}

	gdisk -l ${d} | sed 's/^/    /'
	printf "do you confirm? [N/y]: "
	read choice
	if [ x${choice} != xy ]; then
		echo "ok, aborting"
		exit 1
	fi
}


if [ ${#} -ne 1 ]; then
	echo usage: ${0} "<usb-device>"
	echo
	echo where
	echo -e "\tusb-device    path to usb device to prepare"
	echo
	echo "if usb device is raw device like /dev/sdb, whole drive will be"
	echo "partitioned - 128M for keys, and rest of device for user data"
	echo "if usb device is subdevice like /dev/sdb1, disk will not be"
	echo "partitioned but only /dev/sdb1 will be formated and touched"
	exit
fi


## ==========================================================================
#                          _____ / /_ ____ _ _____ / /_
#                         / ___// __// __ `// ___// __/
#                        (__  )/ /_ / /_/ // /   / /_
#                       /____/ \__/ \__,_//_/    \__/
## ==========================================================================


key_dev=
dev=${1}
if echo "${dev}" | grep -P "[0-9]$"; then
	# dealing with subdevice, only format is required here as we do not
	# touch paritions
	confirm ${dev} "Following device will be formated"
	mkfs.ext4 ${d} -Lcrypt-boot
	key_dev=${d}
else
	confirm ${dev} "Following device will be repartitioned and reformated"
	dd if=/dev/zero of=${dev} count=1024 bs=1024
	gdisk ${dev} <<EOF
n${comment_create_new_partition}
${comment_accept_default_first_drive}
${comment_accept_default_beggining_of_partition}
+128M${comment_size_of_partition_with_keys}
${comment_accept_default_partition_code}
n${comment_create_new_partition}
${comment_accept_default_now_second_drive}
${comment_accept_default_beggining_of_partition}
${comment_accept_default_last_sector_this_will_take_all_space_that_is_left}
0700${comment_select_windows_basic_data_type_partition}
w${comment_write_changes_to_disk}
Y${confirm_overwritting_disk}
EOF

	echo "current disk status"
	gdisk -l ${d} | sed 's/^/    /'
	# format
	echo "creating ext4 on ${d}1"
	mkfs.ext4 ${d}1 -Lcrypt-boot
	echo "creating vfat on ${d}2"
	mkfs.vfat ${d}2
	key_dev=${d}1
fi

# copy keys to drive
mnt=$(mktemp -d)
mount ${key_dev} ${mnt}
cp -r * ${mnt}
umount ${mnt}
rmdir ${mnt}
