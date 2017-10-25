# This does not require an install as the version used
# for the single node test can be used here aswell.

required_envvars fullLinpack_NB fullLinpack_MemoryPerNode

function run_benchmark() {

    # run the LINPACK benchmark
    mpiRanks=$(bc <<< "$instanceCount * 2")
    fullLinpack_Q=$instanceCount
    fullLinpack_P=2
    # taken from here: http://www.crc.nd.edu/~rich/CRC_Summer_Scholars_2014/HPL-HowTo.pdf
    fullLinpack_N=$(bc <<< "((sqrt(${fullLinpack_MemoryPerNode}*${instanceCount}*1024^3/8))/${fullLinpack_NB})*${fullLinpack_NB}")

    execute_timeout_duration=${benchmarkTimeout:-1800}
    execute "run_full_linpack" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd hpl && mpirun -np $mpiRanks -ppn 2 -hostfile \$HOME/bin/hostlist ./xhpl_intel64_static -n $fullLinpack_N -p $fullLinpack_P -q $fullLinpack_Q -nb $fullLinpack_NB'"
    
    benchmarkData="{}"

}