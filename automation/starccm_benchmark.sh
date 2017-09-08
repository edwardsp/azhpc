required_envvars numberOfNodesToTest processesPerNode podKey

function run_benchmark() {
    execute "install_starccm" ssh hpcuser@${public_ip} "./azhpc/install/install_StarCCM_1202.sh $podKey"
    execute "download_starccm_model" ssh hpcuser@${public_ip} "wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/LeMans_100M.tgz -O - | tar zx"
    execute "create_machinefile" ssh hpcuser@${public_ip} "sed 's/$/:${processesPerNode}/g' bin/hostlist | tee machinefile"

    numProcs=$(bc <<< "$instanceCount * $processesPerNode")

    nps=
    for n in $numberOfNodesToTest; do
        if [ "$nps" != "" ]; then
            nps="${nps},"
        fi
        nps="${nps}$(bc <<< "$n * $processesPerNode")"
    done

    execute "run_starccm_benchmark" ssh hpcuser@${public_ip} "starccm+ -np ${numProcs} -machinefile machinefile -power -podkey $podKey -rsh ssh -mpi intel -cpubind bandwidth,v -mppflags '-genv I_MPI_DAPL_PROVIDER ofa-v2-ib0 -genv I_MPI_DAPL_UD 0 -genv I_MPI_DYNAMIC_CONNECTION 0' LeMans_100M.sim -benchmark:\"-preclear -preits 40 -nits 20 -nps $nps\""
}
