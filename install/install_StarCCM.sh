#!/bin/bash
LICIP=$1
HOST=`hostname`
echo $LICIP,$HOST

sudo yum groupinstall -y "X Window System"

mkdir -p /mnt/resource/scratch/applications
mkdir -p /mnt/resource/scratch/INSTALLERS

cd /mnt/resource/scratch/INSTALLERS
wget -q 'http://ninalogs.blob.core.windows.net/application/STAR-CCM+11.04.012_01_linux-x86_64-r8.tar.gz?sv=2017-04-17&ss=bfqt&srt=sco&sp=rw&se=2027-09-27T10:07:48Z&st=2017-09-27T02:07:48Z&spr=https&sig=IXNV8%2B2mGTuWoRvn5ZcHpdzY9MtEeqN8ootSz%2BLez2w%3D' -O - | tar zx

cd /mnt/resource/scratch/INSTALLERS/starccm+_11.04.012

cat <<EOF >> $HOME/.bashrc
export PODKey=$LICIP
export CDLMD_LICENSE_FILE=1999@flex.cd-adapco.com
export PATH=/mnt/resource/scratch/applications/STAR-CCM+11.04.012-R8/star/bin:/opt/intel/impi/5.1.3.181/bin64:\$PATH
EOF

sh /mnt/resource/scratch/INSTALLERS/starccm+_11.04.012/STAR-CCM+11.04.012_01_linux-x86_64-2.5_gnu4.8-r8.bin -i silent -DINSTALLDIR=/mnt/resource/scratch/applications -DNODOC=true -DINSTALLFLEX=false

