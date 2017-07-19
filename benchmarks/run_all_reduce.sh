#!/bin/sh

NPROCS_LIST=$1
PPN_LIST=$2
NITER=$3
REPEATS=$4
NAME_TAG=$5
MPI_FLAGS=$6

echo "NPROCS_LIST = $NPROCS_LIST"
echo "PPN_LIST    = $PPN_LIST"
echo "NITER       = $NITER"
echo "REPEATS     = $REPEATS"
echo "NAME_TAG    = $NAME_TAG"
echo "MPI_FLAGS   = $MPI_FLAGS"

for REP in $(seq $REPEATS); do
	for NPROCS in $NPROCS_LIST; do
		for PPN in $PPN_LIST; do
			NP=$(bc <<< "$NPROCS * $PPN")
			mpirun -np $NP -ppn $PPN -hostfile $HOME/bin/hostlist $MPI_FLAGS IMB-MPI1 Allreduce -iter ${NITER} -npmin $NP -msglog 3:4 -time 1000000 2>&1 | tee IMB_Allreduce_${NITER}_${NP}_${NPROCS}x${PPN}_${REP}${NAME_TAG}.log
		done
	done
done

