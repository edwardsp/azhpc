#!/bin/bash
USER=$1
LICIP=$2
DOWN=$3
HOST=$(hostname)
echo $USER,$LICIP,$HOST,$DOWN

mkdir /mnt/resource/scratch/ansys
mkdir /mnt/resource/scratch/ansys/benchmark
mkdir /mnt/resource/scratch/ansys/INSTALLERS
mkdir /mnt/resource/scratch/ansys/INSTALLERS/ANSYS

wget -q http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/$DOWN -O /mnt/resource/scratch/ansys/benchmark/$DOWN
wget -q https://raw.githubusercontent.com/tanewill/5clickTemplates/master/RawANSYSCluster/runme.jou -O /mnt/resource/scratch/ansys/benchmark/runme.jou
wget -q http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/ANSYS.tgz -O /mnt/resource/scratch/ansys/ANSYS.tgz
tar -xzf /mnt/resource/scratch/ansys/ANSYS.tgz -C /mnt/resource/scratch/ansys/INSTALLERS
tar -xvf /mnt/resource/scratch/ansys/benchmark/$DOWN -C /mnt/resource/scratch/ansys/benchmark
mv /mnt/resource/scratch/ansys/benchmark/*.dat.gz /mnt/resource/scratch/ansys/benchmark/benchmark.dat.gz
mv /mnt/resource/scratch/ansys/benchmark/*.cas.gz /mnt/resource/scratch/ansys/benchmark/benchmark.cas.gz

cd /mnt/resource/scratch/ansys/INSTALLERS/ANSYS/
mkdir -p /mnt/resource/scratch/ansys/applications/ansys_inc/shared_files/licensing/

echo SERVER=1055@$LICIP > /mnt/resource/scratch/ansys/applications/ansys_inc/shared_files/licensing/ansyslmd.ini
echo ANSYSLI_SERVERS=2325@$LICIP >> /mnt/resource/scratch/ansys/applications/ansys_inc/shared_files/licensing/ansyslmd.ini

echo export FLUENT_HOSTNAME=$HOST >> /home/$USER/.bashrc
echo export INTELMPI_ROOT=/opt/intel/impi/5.1.3.181 >> /home/$USER/.bashrc
echo export I_MPI_FABRICS=shm:dapl >> /home/$USER/.bashrc
echo export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 >> /home/$USER/.bashrc
echo export I_MPI_ROOT=/opt/intel/compilers_and_libraries_2016.2.181/linux/mpi >> /home/$USER/.bashrc
echo export PATH=/mnt/resource/scratch/ansys/applications/ansys_inc/v172/fluent/bin:/opt/intel/impi/5.1.3.181/bin64:$PATH >> /home/$USER/.bashrc
echo export I_MPI_DYNAMIC_CONNECTION=0 >> /home/$USER/.bashrc

source /mnt/resource/scratch/ansys/INSTALLERS/ANSYS/INSTALL -silent -install_dir "/mnt/resource/scratch/ansys/applications/ansys_inc/" -fluent
#source /mnt/resource/scratch/ansys/INSTALLERS/ANSYS/INSTALL -silent -install_dir "/mnt/resource/scratch/ansys/applications/ansys_inc/" -cfx




