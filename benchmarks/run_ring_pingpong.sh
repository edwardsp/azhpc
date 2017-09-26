#!/bin/bash

hostlist=$HOME/bin/hostlist

src=$(tail -n1 $hostlist)
for line in $(<$hostlist); do
    dst=$line
    mpirun -np 2 -ppn 1 -hosts $src,$dst IMB-MPI1 PingPong | tee ${src}_to_${dst}_pingpong.log
    src=$dst
done
