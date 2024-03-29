Creates initrd for my purpose, there are a lot of assumptions here

- must be created on system that will use this initrd
- initrd is tightly coupled with current kernel in /usr/src/linux
- /usr/src/linux points to linux version for which initrd will be built
  format is /usr/src/linux -> linux-5.10.3-gentoo
- enable in kernel, dm-crypt, initramfs and userspace api for crypto
- rootfs is zfs
- zfs modules **MUST** be emerged before running this script, zfs module
  are working only with the version they are compiled for. I've noticed that
  even changing patch can break zfs, so reemerge zfs every time you rebuild
  kernel. This is main reason why this script creates initrd that is attached
  to specific kernel version
- full disk encryption with luks and my ../crypto based usb
- gentoo os is used, it's possible some paths are gentoo specific,
  it's true especially for binaries derived from systemdown like udev
- disk where root is must be gpt formatted
- root partition must have partlabel set to "root" (set with gptdisk, gdisk)
- zfs legacy mount is set:
  zfs set mountpoint=legacy root  # root is name of imported pool
- cryptsetup is statically linked - otherwise you might get missing 
  libgcc_s.so.1 error
- gptfdisk should be static as well, otherwise there might be a problem with
  libstdc++.so.6


Getting auth over network to work
1. generate new keyfile, this keyfile will be specific to machine it's generated
on: "dropbearkey -f id_rsa_crypto -t rsa -s 2048" (must be dropbear or there
might be connection errors, as it seems dropbear can't handle openssh keys)
2. generate public key
  dropbearkey -y -f id_rsa_crypto | grep "^ssh-rsa " > id_rsa_crypto.pub
3. add public key to /root/.ssh/authorized_keys to key server
