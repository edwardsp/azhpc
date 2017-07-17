#!/bin/sh

NPROCS_LIST=$1
PPN_LIST=$2
NITER=$3
REPEATS=$4
NAME_TAG=$5

echo "NPROCS_LIST = $NPROCS_LIST"
echo "PPN_LIST    = $PPN_LIST"
echo "NITER       = $NITER"
echo "REPEATS     = $REPEATS"
echo "NAME_TAG    = $NAME_TAG"

for MSG_SZ in 8 16; do
	for REP in $(seq $REPEATS); do
		echo "MSG_SZ=${MSG_SZ} REP=${REP}"
		echo -n "NPROCS/PPN"
		for PPN in $PPN_LIST; do
			echo -n " ${PPN}"
		done
		echo
		for NPROCS in $NPROCS_LIST; do
			echo -n "${NPROCS}"
			for PPN in $PPN_LIST; do
				NP=$(bc <<< "$NPROCS * $PPN")
				echo -n " $(grep -E " $MSG_SZ[ ]+$NITER " IMB_Allreduce_${NITER}_${NP}_${NPROCS}x${PPN}_${REP}${NAME_TAG}.log | sed 's/  */ /g' | cut -d' ' -f 6)"
			done
			echo
		done
	done
done

