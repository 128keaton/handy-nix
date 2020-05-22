#!/bin/bash

############################################################
# How to use:
# WORKDIR is the directory where the cloned system will be created. By default, the rsync flags exclude this folder
# SOURCEPATH = the root of the system you'd like to clone.
# For instance, I'll have a VMDK of a Linux system pre-configured. I can mount this VMDK and clone it for a PXE boot NFS root
#############################################################
# Base variables
WORKDIR="/cloned-system"
SOURCEPATH="/source-system"

# rsync arguments
RSYNC_SRC="$SOURCEPATH/."
RSYNC_DEST="$WORKDIR/."
RSYNC_ARGS=$(cat <<-END
-av \
--exclude=/proc \
--exclude=$WORKDIR \
--exclude=/dev \
--exclude=/snap \
--exclude=/mnt \
--exclude=/media \
--exclude=/swapfile \
--exclude=/run/user/1000/gvfs \
--exclude=/vmlinuz \
--exclude=/vmlinuz.old \
--exclude=/initrd.img \
--exclude=/initrd.img.old \
--exclude=/linux-live \
--exclude=/lost+found \
--exclude=/tmp \
--exclude='*.log.*' \
--exclude='*~' \
--exclude=/sys \
--exclude='*.pid' \
--exclude='*.bak' \
--exclude='*.[0-9].gz' \
--exclude='*.deb' \
--exclude='kdecache*' \
--no-whole-file \
--no-inc-recursive
END
)

# Shell colors
# shellcheck disable=SC2034
red=$'\e[1;31m'
green=$'\e[1;32m'
yellow=$'\e[1;33m'
blue=$'\e[1;34m'
magenta=$'\e[1;35m'
cyan=$'\e[1;36m'
end=$'\e[0m'

#############################################################

if [ $(dpkg-query -W -f='${Status}' pv 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  printf "%s\n" "${red}Package 'pv' is not installed. Installing now. ${end}"
  apt install pv &>/dev/null;
  printf "%s\n" "${green}Successfully installed 'pv'! ${end}"
fi

spin()
{
  spinner="/|\\-/|\\-"
  while :
  do
    for i in $(seq 0 7)
    do
      echo -n "${spinner:$i:1}"
      echo -en "\010"
      sleep 0.2
    done
  done
}


printf "%s\n" "${yellow}"
echo "#############################################################"
echo "SOURCEPATH: $SOURCEPATH (copy from)"
echo "WORKDIR: $WORKDIR (copy to)"
echo "#############################################################"
printf "%s\n" "${end}"

# Creating system structure
printf "%s\n" "${blue}Creating system structure in $WORKDIR. ${end}"
mkdir -p $WORKDIR/{dev,etc,proc,tmp,sys,mnt,media/cdrom,var,boot,home,root,sbin,run,bin,lib,usr,lib64,lib32}
rsync -a /dev/urandom $WORKDIR/dev/
chmod ug+rwx,o+rwt $WORKDIR/tmp

printf "%s\n" "${blue}Determining files to copy from system to $WORKDIR. ${cyan}"

spin &
SPIN_PID=$!
trap 'kill -9 $SPIN_PID &>/dev/null' $(seq 0 15)
TOTAL=$(rsync ${RSYNC_ARGS}  --dry-run  ${RSYNC_SRC} ${RSYNC_DEST} | wc -l)

printf "%s\n" "${blue}$TOTAL files to copy.${cyan}"
printf "%s\n" "${blue}Copying system files to $WORKDIR. ${cyan}"

kill -9 $SPIN_PID
rsync ${RSYNC_ARGS} ${RSYNC_SRC} ${RSYNC_DEST} | pv -lep -s $TOTAL >/dev/null

printf "%s\n" "${magenta}Cleaning up files not needed for the system in $WORKDIR. ${end}"
rm -rf $WORKDIR/etc/apt/sources.list.d/*.save &> /dev/null # Clean up unneeded APT sources
rm -rf $WORKDIR/etc/apt/apt.conf.d/* &> /dev/null          # Remove APT configuration
rm -rf $WORKDIR/etc/apt/preferences.d/* &> /dev/null       # Remove APT preferences
rm -rf $WORKDIR/var/lib/apt/lists/* -vf &> /dev/null       # Clean up unneeded APT sources
rm -rf $WORKDIR/var/lib/apt/lists/lock &> /dev/null        # Remove APT lock files

find $WORKDIR/var/cache/apt -type f -exec rm -rf '{}' \; &> /dev/null
find $WORKDIR/var/cache/apt-xapian-index -type f -exec rm -rf '{}' \; &> /dev/null
find $WORKDIR/var/lib/apt -type f -exec rm -rf '{}' \; &> /dev/null

rm -rf $WORKDIR/var/lib/ureadahead/pack &> /dev/null
rm -f $WORKDIR/etc/X11/xorg.conf*
rm -f $WORKDIR/etc/{hostname,mtab*,fstab}

rm -f $WORKDIR/etc/udev/rules.d/70-persistent*
rm -f $WORKDIR/etc/cups/ssl/{server.crt,server.key}
rm -f $WORKDIR/etc/ssh/*key*
rm -f $WORKDIR/var/lib/dbus/machine-id

rsync -a /dev/urandom $WORKDIR/dev/
find $WORKDIR/var/log/ $WORKDIR/var/lock/ $WORKDIR/var/backups/ $WORKDIR/var/tmp/ $WORKDIR/var/crash/ $WORKDIR/var/lib/ubiquity/ -type f -exec rm -f {} \;

rm -rf $WORKDIR/home/er2/.ICEauthority
rm -rf $WORKDIR/home/er2/.Xauthority

rm -rf $WORKDIR/home/er2/.local/share/Trash
rm -rf $WORKDIR/home/er2/.local/gvfs-metadata
rm -rf $WORKDIR/home/er2/.cache
rm -rf $WORKDIR/home/er2/.xsession-errors*
rm -rf $WORKDIR/home/er2/.gvfs
rm -rf $WORKDIR/home/er2/.local/share/gvfs-metadata

# Fixes dbus's machine ID issue
rm -rf $WORKDIR/var/lib/dbus/machine-id
rm -rf $WORKDIR/etc/machine-id
touch $WORKDIR/var/lib/dbus/machine-id
touch $WORKDIR/etc/machine-id

# Disable waiting for network on boot because systemd can suck my ass
printf "%s\n" "${blue}Disabling systemd network wait online service because systemd ${red}sucks ${blue}"
systemctl disable NetworkManager-wait-online.service --root=$WORKDIR
systemctl disable systemd-networkd-wait-online.service --root=$WORKDIR
systemctl daemon-reload --root=$WORKDIR
echo 'CONFIGURE_INTERFACES=no' >> $WORKDIR/etc/default/networking

rm -rf $WORKDIR/var/log/journal

# Creating Network Update Script
printf "%s\n" "${blue}Creating network update script. ${end}"
touch $WORKDIR/etc/network/if-up.d/update
echo "#!/bin/sh" >>  $WORKDIR/etc/network/if-up.d/update
echo "apt-get update" >> $WORKDIR/etc/network/if-up.d/update
chmod 755 $WORKDIR/etc/network/if-up.d/update
chmod +x $WORKDIR/etc/network/if-up.d/update

printf "%s\n" "${yellow}Copying kernel and initial ramdisk. ${end}"
cp -pdRx $SOURCEPATH/vmlinuz $WORKDIR/vmlinuz
cp -pdRx $SOURCEPATH/initrd.img $WORKDIR/initrd.img

printf "%s\n" "${magenta}Fixing permissions on kernel and initial ramdisk. ${end}"
chmod -R 777 $WORKDIR/initrd.img $WORKDIR/vmlinuz # Fix permissions on the initial ramdisk and the kernel
chmod -R 555 $WORKDIR/sys $WORKDIR/proc           # Fix permissions on /sys and /proc
chmod -R 700 $WORKDIR/root                        # Fix permissions on /root
chmod -R 755 $WORKDIR/run $WORKDIR/sbin $WORKDIR/bin $WORKDIR/etc $WORKDIR/home $WORKDIR/lib

chmod 755 $WORKDIR/usr                            # Fix permissions on /usr
chown root:root $WORKDIR/usr/bin/sudo             # Set sudo to be owned by root
chmod 4755 $WORKDIR/usr/bin/sudo                  # Set uid on sudo
chmod 644 $WORKDIR/lib/systemd/system/*.service
chown root:messagebus $WORKDIR/usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod 4754 $WORKDIR/usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod u+s $WORKDIR/usr/lib/dbus-1.0/dbus-daemon-launch-helper
touch $WORKDIR/dev/pts

printf "%s\n" "${blue}Enabling ping for non-admins. ${end}"
setcap 'cap_net_admin,cap_net_raw+ep' $WORKDIR/bin/ping   # Allow non-admins to ping

# Set the resolv.conf to what Aiken Workbench sets their resolv.conf to
printf "%s\n" "${blue}Creating resolv.conf. ${end}"
echo "nameserver ${NAMESERVER}" > $WORKDIR/etc/resolv.conf
printf "%s\n" "${green}DNS resolves to $NAMESERVER. ${end}"

printf "%s\n" "${yellow}Mounting /dev/ and /dev/pts in chroot... ${end}"
mkdir -p -m 755 $WORKDIR/dev/pts &> /dev/null
mount -t devtmpfs -o mode=0755,nosuid devtmpfs $WORKDIR/dev &> /dev/null
mount -t devpts -o gid=5,mode=620 devpts $WORKDIR/dev/pts &> /dev/null

printf "%s\n" "${yellow}Reinstalling dbus ${end}"
spin &
SPIN_PID=$!
trap 'kill -9 $SPIN_PID &>/dev/null' $(seq 0 15)

chroot $WORKDIR /bin/bash <<"EOT"
wget -q -O dbus.deb http://archive.ubuntu.com/ubuntu/pool/main/d/dbus/dbus_$(dpkg-query --showformat='${Version}' --show dbus)_amd64.deb
apt install --reinstall ./dbus.deb &> /dev/null
rm -r dbus.deb
EOT

kill -9 $SPIN_PID

chmod 666 /dev/null
umount -R $WORKDIR/dev/pts
umount -R $WORKDIR/dev
printf "%s\n" "${green}Done! ${end}"
