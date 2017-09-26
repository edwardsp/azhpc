#!/bin/bash
LICIP=$1
HOST=`hostname`
echo $LICIP,$HOST

#sudo yum groupinstall -y "X Window System"

mkdir -p /mnt/resource/scratch/applications
mkdir -p /mnt/resource/scratch/INSTALLERS

cd /mnt/resource/scratch/INSTALLERS

sudo yum install -y libXext libXt
axel -q -n 50 http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/STAR-CCM+12.02.010_01_linux-x86_64.tar.gz
tar xzf STAR-CCM+12.02.010_01_linux-x86_64.tar.gz

#wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/STAR-CCM+12.02.010_01_linux-x86_64.tar.gz -O - | tar zx

cd /mnt/resource/scratch/INSTALLERS/starccm+_12.02.010

cat <<EOF >> $HOME/.bashrc
export PODKey=$LICIP
export CDLMD_LICENSE_FILE=1999@flex.cd-adapco.com
export PATH=/mnt/resource/scratch/applications/12.02.010/STAR-CCM+12.02.010/star/bin:/opt/intel/compilers_and_libraries_2017.2.174/linux/mpi/intel64/bin:\$PATH
EOF

sh /mnt/resource/scratch/INSTALLERS/starccm+_12.02.010/STAR-CCM+12.02.010_01_linux-x86_64-2.5_gnu4.8.bin -i silent -DINSTALLDIR=/mnt/resource/scratch/applications -DNODOC=true -DINSTALLFLEX=false
