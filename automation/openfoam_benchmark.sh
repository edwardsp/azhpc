required_envvars processesPerNode numberOfIterations storageAccountName storageContainerName storageBenchmarkPath storageBenchmarkName storageSasKey

function run_benchmark() {
    execute "install_openfoam" ssh hpcuser@${public_ip} "./azhpc/install/install_openfoam.sh"
    benchmarkName="${storageBenchmarkName}_${instanceCount}x${processesPerNode}"
    execute "download_openfoam_model" ssh hpcuser@${public_ip} "wget -q 'https://$storageAccountName.blob.core.windows.net/$storageContainerName/$storageBenchmarkPath/${benchmarkName}.tar$storageSasKey' -O - | tar x"

    numProcs=$(bc <<< "$instanceCount * $processesPerNode")

    execute "run_openfoam_benchmark" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd $benchmarkName && sed -i "s/^endTime .*;$/endTime ${numberOfIterations};/g" system/controlDict && mpirun -np $numProcs -ppn $processesPerNode -hostfile \$HOME/bin/hostlist simpleFoam -parallel'"
}
