#!/bin/sh

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <BENCHMARK>"
	echo "Benchmarks available: sedan_4m, f1_racecar_140m"
	exit 1
fi

BENCHMARK=$1

echo "Benchmark: $BENCHMARK"

wget 'http://ninalogs.blob.core.windows.net/application/${BENCHMARK}.tar?sv=2017-04-17&ss=bfqt&srt=sco&sp=rw&se=2027-09-27T10:07:48Z&st=2017-09-27T02:07:48Z&spr=https&sig=IXNV8%2B2mGTuWoRvn5ZcHpdzY9MtEeqN8ootSz%2BLez2w%3D' -O - | tar x || exit 1

cat <<EOF >run_${BENCHMARK}.jou
f r-c-d ${BENCHMARK}.cas.gz
par lat
par band
s iterate 100
parallel timer usage
exit y
EOF

echo "Complete - use the following command to run:"
echo "    fluent 3d -g -mpi=intel -pib.dapl -ssh -t256 -cnf=hosts -i ${BENCHMARK}.jou"
