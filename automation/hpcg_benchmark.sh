required_envvars processesPerNode

function run_benchmark() {
    execute "get_hpcg_benchmark" ssh hpcuser@${public_ip} "wget -q 'https://paedwar.blob.core.windows.net/public/hpcg-bin.tgz' -O - | tar zx"
    
    numProcs=$(bc <<< "$instanceCount * $processesPerNode")

    execute "run_hpcg_benchmark" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd hpcg-bin && mpirun -np $numProcs -ppn $processesPerNode -hostfile \$HOME/bin/hostlist ./xhpcg'"

    execute "get_hpcg_results" ssh hpcuser@${public_ip} "cat hpcg-bin/HPCG-Benchmark_*"

    HPCG_GFLOPs=$(grep "rating of" $(get_log get_hpcg_results) | cut -d'=' -f2)

    benchmarkData="{ \"GFLOPs\" : \"$HPCG_GFLOPs\" }"
}
