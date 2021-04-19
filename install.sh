#!/bin/bash
# Make sure this script is run as sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Create a directory for the OpenC2X downloads and navigate to it
USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
cd $USER_HOME
mkdir OpenC2X_Image
cd OpenC2X_Image

# get the tinycore package from pc engines
# wget https://www.pcengines.ch/file/apu_tinycore.tar.bz2

wget https://www.pcengines.ch/file/apu_tinycore.tar.bz2

# get the MBR image file mbr.bin from the syslinux source package at:
# wget https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-4.04.tar.bz2
# (the file is located in: syslinux-4.04/mbr/mbr.bin)
# move the mbr.bin into the OpenC2X_Image directory.

wget https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-4.04.tar.bz2
tar -xvjf syslinux-4.04.tar.bz2 && cp syslinux-4.04/mbr/mbr.bin . && rm -rf syslinux-4.04 syslinux-4.04.tar.bz2

# Set the FILESDIR variable on your shell and select the USB device to write to. 
FILESDIR=$USER_HOME/OpenC2X_Image
echo "--------------------------------------------------------"
lsblk | grep sd
echo "--------------------------------------------------------"
echo "Please select your USB drive from the device list above. It must begin with /dev/ and typed in this format: /dev/sdb"
echo && echo "---->" && read DEVICE
echo "--------------------------------------------------------"
echo "The USB device you have selected is:" $DEVICE
echo "--------------------------------------------------------"

# partition and format
umount ${DEVICE}1
dd if=/dev/zero of=${DEVICE} count=1 conv=notrunc
echo -e "o\nn\np\n1\n\n\nw" | fdisk ${DEVICE}
mkfs.vfat -n XENIAL_APU -I ${DEVICE}1

# make the device bootable
syslinux -i ${DEVICE}1
dd conv=notrunc bs=440 count=1 if=$FILESDIR/mbr.bin of=${DEVICE}
parted ${DEVICE} set 1 boot on

## unpack modified installers
mount ${DEVICE}1 /mnt
tar -C /mnt -xjf $FILESDIR/apu_tinycore.tar.bz2

############### This section needs to be run manually outside of the above script. Please do not forget to run these commands otherwise the OpenC2X image will not be copied over to your USB. #################
# !*Copy the OpenC2X Image(lede-x86-64-combined-ext4.img) you just made on your virtual machine or PC to the new OpenC2X_Image folder. *!
# !*This step will need to be done manually. The image would be stored inside the OpenC2X folder at ~/OpenC2X-embedded/bin/targets/x86/64/lede-x86-64-combined-ext4.img.gz. *!
# !*Since you are no longer running the script the commands below will need to be run manually. *!

#   cd $HOME/OpenC2X_Image
#   sudo cp lede-x86-64-combined-ext4.img /mnt
#   sudo umount /mnt
