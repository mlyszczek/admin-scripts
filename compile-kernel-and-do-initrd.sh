#!/bin/sh

set -e

if [ $UID -ne 0 ]; then
	echo "This script must be run as root"
	exit 2
fi

script_dir=$( (cd $(dirname $0); pwd) )

# this is needed or else external modules won't find kernel
# and thus won't compile
umask 022

echo ":: building kernel"
cd /usr/src/linux
make -j$(nproc)

echo ":: installing kernel"
make install

echo ":: installing modules"
make modules_install

echo ":: prepare kernel for external modules"
make modules_prepare

echo ":: rebuild external modules"
emerge -j @module-rebuild --usepkg-exclude '*/*'

echo ":: create initrd"
if [ "$1" ]; then
	$script_dir/initrd/create-initrd.sh $1
else
	$script_dir/initrd/create-initrd.sh
fi

echo ":: generating new grub config"
set +e
mount /boot >/dev/null 2>/dev/null # /boot might be already mounted
set -e
grub-mkconfig -o /boot/grub/grub.cfg

echo ":: all done:)"
