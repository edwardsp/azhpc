#!/bin/bash
USER=$1
LICIP=$2
HOST=$(hostname)
echo $USER,$LICIP,$HOST

sudo yum groupinstall -y "X Window System"

mkdir /mnt/resource/scratch
mkdir /mnt/resource/scratch/INSTALLERS

cd /mnt/resource/scratch/INSTALLERS
wget -q 'http://ninalogs.blob.core.windows.net/application/ANSYS.tgz?sv=2017-04-17&ss=bfqt&srt=sco&sp=rw&se=2027-09-27T10:07:48Z&st=2017-09-27T02:07:48Z&spr=https&sig=IXNV8%2B2mGTuWoRvn5ZcHpdzY9MtEeqN8ootSz%2BLez2w%3D' -O - | tar zx

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




