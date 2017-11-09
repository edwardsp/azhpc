#!/bin/sh

cd $HOME
wget "https://www.paraview.org/paraview-downloads/download.php?submit=Download&version=v5.4&type=binary&os=Linux&downloadFile=ParaView-5.4.1-Qt5-OpenGL2-MPI-Linux-64bit.tar.gz" -O - | tar zx

sudo yum install -y mesa-libGLU libSM libXt
pdsh 'sudo yum install -y mesa-libGLU libSM libXt'

cat <<EOF >> $HOME/.bashrc
export LD_LIBRARY_PATH=\$HOME/ParaView-5.4.1-Qt5-OpenGL2-MPI-Linux-64bit/lib:\$LD_LIBRARY_PATH
export PATH=\$HOME/ParaView-5.4.1-Qt5-OpenGL2-MPI-Linux-64bit/bin:\$PATH
EOF


