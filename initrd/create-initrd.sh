#!/bin/bash

tmpd=$(mktemp -d)
script_dir=$( (cd $(dirname $0); pwd) )

at_exit()
{
	if [ $rc -eq 1 ]; then
		echo "Error creating initrd, $tmpd with image not removed!"
		exit $rc
	fi

	if [ "$tmpd" -a $tmpd != / ]; then rm -rf $tmpd; fi
	exit $rc
}
trap at_exit EXIT


## ==========================================================================
#                              ⢀⣀⢀⡀⣀⡀⢀⣀⣰⡀⢀⣀⣀⡀⣰⡀⢀⣀
#                              ⠣⠤⠣⠜⠇⠸⠭⠕⠘⠤⠣⠼⠇⠸⠘⠤⠭⠕
## ==========================================================================
kernel_version=$(readlink /usr/src/linux | cut -f2- -d-)
initrd_file=/boot/initrd-$kernel_version

## ==========================================================================
#                               ⡀⢀⢀⣀⡀⣀⠄⢀⣀⣇⡀⡇⢀⡀⢀⣀
#                               ⠱⠃⠣⠼⠏ ⠇⠣⠼⠧⠜⠣⠣⠭⠭⠕
## ==========================================================================
rc=0

## ==========================================================================
#                         ⣇⡀⠄⣀⡀⢀⣀⡀⣀⠄⢀⡀⢀⣀ ⣰⡀⢀⡀ ⢀⣀⢀⡀⣀⡀⡀⢀
#                         ⠧⠜⠇⠇⠸⠣⠼⠏ ⠇⠣⠭⠭⠕ ⠘⠤⠣⠜ ⠣⠤⠣⠜⡧⠜⣑⡺
#  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   List of binaries to copy to initrd. No spaces in files. Path must be
#   absolute
## ==========================================================================
bins="
	/bin/busybox
	/sbin/cryptsetup
	/sbin/e2label
	/sbin/mount.zfs
	/sbin/switch_root
	/sbin/zfs
	/sbin/zpool
	/usr/bin/dbscp
	/usr/bin/dbclient
	/usr/sbin/gdisk
	/usr/sbin/iscsid
	/usr/sbin/iscsiadm
"


## ==========================================================================
#                         ⣀⣀ ⢀⡀⢀⣸⡀⢀⡇⢀⡀⢀⣀ ⣰⡀⢀⡀ ⢀⣀⢀⡀⣀⡀⡀⢀
#                         ⠇⠇⠇⠣⠜⠣⠼⠣⠼⠣⠣⠭⠭⠕ ⠘⠤⠣⠜ ⠣⠤⠣⠜⡧⠜⣑⡺
#  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   List of modules that should be copied to initrd, must be relative
#   to root of module path (like /lib/modules/5.10.103-gentoo), modules
#   for current kernel version will be taken.
## ==========================================================================
modules="
	extra/avl/zavl.ko
	extra/icp/icp.ko
	extra/lua/zlua.ko
	extra/nvpair/znvpair.ko
	extra/spl/spl.ko
	extra/unicode/zunicode.ko
	extra/zcommon/zcommon.ko
	extra/zfs/zfs.ko
	extra/zstd/zzstd.ko
"

## ==================================================================
#                        ___ / /_ ___ _ ____ / /_
#                       (_-</ __// _ `// __// __/
#                      /___/\__/ \_,_//_/   \__/
## ==================================================================


# generic errors, crash with rc=2 to remove any tmp files
rc=2

if [ $UID -ne 0 ]; then
	echo "This script must be run as root"
	exit 2
fi

if [[ ! $tmpd =~ /tmp/tmp.* ]]; then
	echo "failed to create tmp file, tmpd is $tmpd"
	exit 2
fi

# if something goes wrong, crash with exit==1
rc=1; set -e

echo "creating initrd in $tmpd"

# create basic dir structure
mkdir -p $tmpd/{boot/crypt,bin,sbin,lib,lib64,mnt/root,tmp,etc,dev,proc,sys}
mkdir -p $tmpd/run/lock
mkdir -p $tmpd/usr/{bin,sbin,lib,lib64}

echo "-- copying binaries"
for b in $bins; do
	echo "---- copy $b and its shared libraries"
	# -a is needed so copy can preserve all special attributes
	# this may be needed for suid bins, where without -a,
	# suid flag won't be copied
	# -L to resolv any symlink that would not work on initrd
	cp -aL $b $tmpd$b
	# lddtree will also return name of file,
	# so skip it with tail
	for l in $(lddtree -l $b | tail -n+2); do
		echo "------ copy $l"
		# files returned by lddtree are usually links
		# to real files, -L will resolv these symlinks
		# so we have real libs on initrd
		cp -L $l $tmpd$l
	done
done
echo

echo "-- copying extra files"
for e in $extra; do
	# extra files might have different paths, we won't
	# be creating them statically, as it's too easy to
	# forget anything, so we simply create needed dir
	# for each extra file. We will duplicate directory
	# creation for sure, but there won't be too much
	# files here for it to be a problem for us.
	mkdir -p $tmpd/$(dirname $e)
	echo "---- copy $e"
	# -r in case extra is a directory not a file
	cp -r $e $tmpd$e
done
echo

echo "-- copy modules"
moddir="/lib/modules/$kernel_version"
mkdir -p $tmpd$moddir
for m in $modules; do
	mkdir -p $tmpd$moddir/$(dirname $m)
	echo "---- copy $moddir/$m"
	cp $moddir/$m $tmpd$moddir/$(dirname $m)
done
# also copy all meta files.
# recently I got error that modules.dep does not exist.
# who knows what else will be needed in the future so copy it all to be safe
cp $moddir/modules.* $tmpd$moddir

if [ "$1" ]; then
	echo $1 > $tmpd/etc/hostname
else
	hostname > $tmpd/etc/hostname
fi

echo "-- copying init"
cp $script_dir/init $tmpd/init
chmod 700 $tmpd/init

echo "-- installing busybox"
$tmpd/bin/busybox --install $tmpd/bin

echo "-- copy fs overlay"
cp -r $script_dir/fs/. $tmpd
echo "-- copy rsa keys"
cp $script_dir/id_rsa_crypto $tmpd/.ssh/id_rsa
cp $script_dir/id_rsa_crypto.pub $tmpd/.ssh/id_rsa.pub
chmod -R g-rwx,o-rwx $tmpd/.ssh

tree -pushag $tmpd

if [ -s $initrd_file ]; then
	mv $initrd_file $initrd_file.old
fi

( cd $tmpd ; find . | cpio -o --format=newc --quiet | gzip -9 ) > $initrd_file

printf ":: built for hostname: "; cat $tmpd/etc/hostname
echo 'done:)'
rc=0
