#!/bin/sh

cd $HOME
wget 'https://ninalogs.blob.core.windows.net/application/OpenFOAM-4.x_gcc48.tgz?sv=2017-04-17&ss=bfqt&srt=sco&sp=rw&se=2027-09-27T10:07:48Z&st=2017-09-27T02:07:48Z&spr=https&sig=IXNV8%2B2mGTuWoRvn5ZcHpdzY9MtEeqN8ootSz%2BLez2w%3D' -O - | tar zx

cat <<EOF >> $HOME/.bashrc
if [[ ! -z "\$I_MPI_ROOT" ]]; then
	export MPI_ROOT=\$I_MPI_ROOT
	source \$HOME/OpenFOAM/OpenFOAM-4.x/etc/bashrc
fi
EOF


