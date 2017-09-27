required_envvars processesPerNode numberOfIterations storageAccountName storageContainerName storageBenchmarkPath storageBenchmarkName storageSasKey

function run_benchmark() {
    execute "install_openfoam" ssh hpcuser@${public_ip} "./azhpc/install/install_openfoam.sh"
    benchmarkName="${storageBenchmarkName}_${instanceCount}x${processesPerNode}"
    execute "download_openfoam_model" ssh hpcuser@${public_ip} "wget -q 'https://$storageAccountName.blob.core.windows.net/$storageContainerName/$storageBenchmarkPath/${benchmarkName}.tar$storageSasKey' -O - | tar x"

    numProcs=$(bc <<< "$instanceCount * $processesPerNode")

    # set one extra iteration to run as we will calculate by taking the end of last iteration minus the end of first iteration (therefore no IO)
    niters=$(bc <<< "$numberOfIterations + 1")
    if [ "$runPotentialFoam" = true ]; then
        execute "run_potentialFoam" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd $benchmarkName && mpirun -np $numProcs -ppn $processesPerNode -hostfile \$HOME/bin/hostlist potentialFoam -parallel'"
    fi
    execute "run_openfoam_benchmark" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd $benchmarkName && sed -i \"s/^endTime .*;$/endTime ${niters};/g\" system/controlDict && mpirun -np $numProcs -ppn $processesPerNode -hostfile \$HOME/bin/hostlist simpleFoam -parallel'"
    
    
    of_logfile=$(get_log run_openfoam_benchmark)
    start_time=$(grep ExecutionTime $of_logfile | head -n1 | cut -d' ' -f8)
    end_time=$(grep ExecutionTime $of_logfile | tail -n1 | cut -d' ' -f8)
    clockTime=$(echo "$end_time - $start_time" | bc)

    benchmarkData=$(jq -n '.openfoam.results.name=$storageBenchmarkName | .openfoam.results.numberOfRanks=$numProcs | .openfoam.results.processorsPerNode=$processesPerNode | .openfoam.results.numberOfIterations=$numberOfIterations | .openfoam.results.clockTime=$clockTime' --arg storageBenchmarkName $storageBenchmarkName --arg processesPerNode $processesPerNode --arg numProcs $numProcs --arg numberOfIterations $numberOfIterations --arg clockTime $clockTime)

}
