#!/bin/bash

HEADNODE=10.0.0.4

sed -i 's/^ResourceDisk.MountPoint=\/mnt\/resource$/ResourceDisk.MountPoint=\/mnt\/local_resource/g' /etc/waagent.conf
umount /mnt/resource

mkdir -p /mnt/resource/scratch

cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
EOF

cat << EOF >> /etc/fstab
$HEADNODE:/home    /home   nfs defaults 0 0
$HEADNODE:/mnt/resource/scratch    /mnt/resource/scratch   nfs defaults 0 0
EOF

yum --enablerepo=extras install -y -q epel-release
yum install -y -q nfs-utils htop pdsh psmisc
setsebool -P use_nfs_home_dirs 1

mount -a

# Don't require password for HPC user sudo
echo "hpcuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# Disable tty requirement for sudo
sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers
