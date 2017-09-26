#!/bin/bash

scriptUri=$1
githubUser=$(echo "$scriptUri" | cut -d'/' -f4)
githubRepo=$(echo "$scriptUri" | cut -d'/' -f5)
githubBranch=$(echo "$scriptUri" | cut -d'/' -f6)

USER=hpcuser

IP=`ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
localip=`echo $IP | cut --delimiter='.' -f -3`

cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
EOF

mkdir -p /mnt/resource/scratch
chmod a+rwx /mnt/resource/scratch

yum --enablerepo=extras install -y -q epel-release
yum install -y -q nfs-utils nmap htop pdsh screen git axel 

cat << EOF >> /etc/exports
/home $localip.*(rw,sync,no_root_squash,no_all_squash)
/mnt/resource/scratch $localip.*(rw,sync,no_root_squash,no_all_squash)
EOF

systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap
systemctl start rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap
systemctl restart nfs-server

mkdir -p /home/$USER/bin
chown $USER:$USER /home/$USER/bin

cat << EOF >> /home/$USER/.bashrc
if [ -d "/opt/intel/impi" ]; then
    source /opt/intel/impi/*/bin64/mpivars.sh
fi
export PATH=/home/$USER/bin:\$PATH
export I_MPI_FABRICS=shm:dapl
export I_MPI_DAPL_PROVIDER=ofa-v2-ib0
export I_MPI_DYNAMIC_CONNECTION=0
export I_MPI_DAPL_TRANSLATION_CACHE=0
export WCOLL=/home/$USER/bin/hostlist
EOF
chown $USER:$USER /home/$USER/.bashrc

touch /home/hpcuser/bin/hostlist
chown hpcuser:hpcuser /home/hpcuser/bin/hostlist

ssh-keygen -f /home/$USER/.ssh/id_rsa -t rsa -N ''
cat << EOF > /home/$USER/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    PasswordAuthentication no
    LogLevel QUIET
EOF
cat /home/$USER/.ssh/id_rsa.pub >> /home/$USER/.ssh/authorized_keys
chmod 644 /home/$USER/.ssh/config
chown $USER:$USER /home/$USER/.ssh/*

# Don't require password for HPC user sudo
echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# Disable tty requirement for sudo
sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

#
# add .screenrc file
#
cat << EOF > /home/$USER/.screenrc
screen -t "top"  0 top
screen -t "bash 1"  0 bash

defscrollback 10000

sessionname local
shelltitle bash
startup_message off

vbell off

bind = resize =
bind + resize +2
bind - resize -2
bind _ resize max

caption always "%{= wr} $HOSTNAME %{= wk} %-Lw%{= wr}%n%f %t%{= wk}%+Lw %{= wr} %=%c %Y-%m-%d "

zombie cr
escape ^]]
EOF
chown $USER:$USER /home/$USER/.screenrc

cd /home/$USER
git clone -b $githubBranch https://github.com/$githubUser/$githubRepo.git
chown $USER:$USER -R azhpc
chmod +x azhpc/scripts/*
cd /home/$USER/bin
for i in /home/$USER/azhpc/scripts/*; do
	ln -s $i
done

rm -f install.py
