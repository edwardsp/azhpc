#!/bin/sh

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <BENCHMARK>"
	echo "Benchmarks available: sedan_4m.tar, f1_racecar_140m"
fi

BENCHMARK=$1

echo "Benchmark: $BENCHMARK"

cat <<EOF >run_${BENCHMARK}.jou
f r-c-d ${BENCHMARK}.cas.gz
par lat
par band
s iterate 100
parallel timer usage
exit y
EOF

wget http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/${BENCHMARK}.tar -O - | tar x

echo "Complete - use the following command to run:"
echo "    fluent 3d -g -mpi=intel -pib.dapl -ssh -t256 -cnf=hosts -i ${BENCHMARK.jou"
