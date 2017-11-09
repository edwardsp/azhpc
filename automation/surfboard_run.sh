required_envvars processesPerNode numberOfIterations surfboardUrl roll depth

function run_benchmark() {
    execute "install_openfoam" ssh hpcuser@${public_ip} "./azhpc/install/install_openfoam.sh"
    execute "install_paraview" ssh hpcuser@${public_ip} "./azhpc/install/install_paraview.sh"
    execute "download_surfboard_case" ssh hpcuser@${public_ip} "git clone https://github.com/edwardsp/surfboard.git"
    numProcs=$(bc <<< "$instanceCount * $processesPerNode")
    mpiArgs="-ppn $processesPerNode -hostfile \$HOME/bin/hostlist"
    execute_timeout_duration=5400
    execute "run_surfboard_case" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd surfboard && ./run.sh \"$surfboardUrl\" $depth $roll $numProcs $numberOfIterations \"$mpiArgs\"'"
    rsync -az --exclude 'processor*' hpcuser@${public_ip}:surfboard $LOGDIR/.

    benchmarkData="{}"
}
