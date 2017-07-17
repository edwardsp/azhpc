#!/bin/sh

pdsh "mpirun -np 2 -genv I_MPI_FABRICS dapl IMB-MPI1 pingpong 2>/dev/null >/dev/null || echo 'fail'"

