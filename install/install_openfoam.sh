#!/bin/sh

cd $HOME
wget https://paedwar.blob.core.windows.net/public/OpenFOAM-4.x_gcc48.tgz -O - | tar zx

cat <<EOF >> $HOME/.bashrc
if [[ ! -z "\$I_MPI_ROOT" ]]; then
	export MPI_ROOT=\$I_MPI_ROOT
	source \$HOME/OpenFOAM/OpenFOAM-4.x/etc/bashrc
fi
EOF


