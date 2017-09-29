function run_benchmark() {
    # run the allreduce benchmark
    for iter in $(seq 1 10); do
        numberOfProcesses=$(bc <<< "$instanceCount * $processesPerNode")
        execute "run_allreduce_iteration_${iter}" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'mpirun -np $numberOfProcesses -ppn $processesPerNode -hostfile \$HOME/bin/hostlist IMB-MPI1 Allreduce -iter 10000 -npmin $numberOfProcesses -msglog 3:4 -time 1000000'"
        if [ "$execute_timeout" = true ]; then
            check_hanging_nodes "allreduce"
            clear_up
            exit 1        
        fi
    done
}