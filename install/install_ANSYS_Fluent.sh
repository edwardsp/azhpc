#!/bin/bash
USER=$1
LICIP=$2
HOST=$(hostname)
echo $USER,$LICIP,$HOST

sudo yum groupinstall -y "X Window System"

mkdir /mnt/resource/scratch
mkdir /mnt/resource/scratch/INSTALLERS

cd /mnt/resource/scratch/INSTALLERS
wget -q http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/ANSYS.tgz -O - | tar zx

cd /mnt/resource/scratch/INSTALLERS/ANSYS/
mkdir -p /mnt/resource/scratch/applications/ansys_inc/shared_files/licensing/

cat <<EOF > /mnt/resource/scratch/applications/ansys_inc/shared_files/licensing/ansyslmd.ini
SERVER=1055@$LICIP
ANSYSLI_SERVERS=2325@$LICIP
EOF

cat <<EOF >> $HOST/.bashrc
export FLUENT_HOSTNAME=$HOST
export PATH=/mnt/resource/scratch/applications/ansys_inc/v172/fluent/bin:\$PATH
EOF

source /mnt/resource/scratch/ansys/INSTALLERS/ANSYS/INSTALL -silent -install_dir "/mnt/resource/scratch/applications/ansys_inc/" -fluent
#source /mnt/resource/scratch/ansys/INSTALLERS/ANSYS/INSTALL -silent -install_dir "/mnt/resource/scratch/applications/ansys_inc/" -cfx




