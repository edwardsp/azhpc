#!/bin/bash

HEADNODE=10.0.0.4

sed -i 's/^ResourceDisk/\#ResourceDisk/g' /etc/waagent.conf

mkdir -p /mnt/resource/scratch

cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
EOF

cat << EOF >> /etc/fstab
$HEADNODE:/home    /home   nfs defaults 0 0
$HEADNODE:/mnt/resource/scratch    /mnt/resource/scratch   nfs defaults 0 0
EOF


if [ "$(grep ubuntu /etc/os-release 2>/dev/null)" != "" ]
then
    apt-get install -y nfs-common nmap htop pdsh git
    
    echo "deb http://archive.ubuntu.com/ubuntu/ xenial-proposed restricted main multiverse universe" >> /etc/apt/sources.list
    apt-get update
    apt-get install -y linux-azure linux-image-extra-4.11.0-1006-azure
    apt-get install -y libdapl2 libmlx4-1

    cd /root
    git clone https://github.com/Azure/WALinuxAgent.git
    cd WALinuxAgent
    apt-get install -y python3-pip
    python3 ./setup.py install --force
    systemctl daemon-reload
    service walinuxagent restart
    # not entirely sure this is being executed
    cat << EOF >> /etc/waagent.conf
OS.EnableRDMA=y
OS.UpdateRdmaDriver=y
EOF
    # now it needs a restart followed by:
    #sudo modprobe rdma_ucm
else
    yum --enablerepo=extras install -y -q epel-release
    yum install -y -q nfs-utils htop pdsh psmisc
    setsebool -P use_nfs_home_dirs 1
fi

mount -a

# Don't require password for HPC user sudo
echo "hpcuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# Disable tty requirement for sudo
sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers
