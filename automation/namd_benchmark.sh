required_envvars processesPerNode

function run_benchmark() {
    execute "download_namd" ssh hpcuser@${public_ip} "wget -q 'https://paedwar.blob.core.windows.net/public/namd2' && chmod +x namd2"
    execute "download_benchmark" ssh hpcuser@${public_ip} "wget -q 'https://paedwar.blob.core.windows.net/public/namd_stmv_benchmark.tgz' -O - | tar zx"
    
    numProcs=$(bc <<< "$instanceCount * $processesPerNode")

    execute "run_benchmark" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd namd_stmv_benchmark && mpirun -np $numProcs -ppn $processesPerNode -hostfile \$HOME/bin/hostlist \$HOME/namd2 stmv.namd'"

    benchmarkData="{}"
}
