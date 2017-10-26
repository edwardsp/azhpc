#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

PDSH_MAX_CONNECTIONS=100

paramsFile=$1
echo "Reading parameters from: $paramsFile"
source $paramsFile
required_envvars rootLogDir githubUser githubBranch resource_group vmSku vmssName computeNodeImage instanceCount processesPerNode rsaPublicKey rootLogDir linpack_N linpack_P linpack_Q linpack_NB
if [ "$logToStorage" = true ]; then
        required_envvars cosmos_account cosmos_database cosmos_collection cosmos_key logStorageAccountName logStorageContainerName logStoragePath logStorageSasKey
fi

benchmarkScript=$2
echo "Benchmark script: $benchmarkScript"
source $benchmarkScript

scriptname=$(basename "$0")
scriptname="${scriptname%.*}"
paramsname=$(basename "$paramsFile")
paramsname="${paramsname%.*}"
benchmarkname=$(basename "$benchmarkScript")
benchmarkname="${benchmarkname%.*}"
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
LOGDIR=$rootLogDir/${scriptname}_${paramsname}_${benchmarkname}_${timestamp}
mkdir $LOGDIR

# creating a new document with a unique id (intention to put in documentdb)
telemetryData="{ \"id\" : \"$(uuidgen)\", \"logDir\" : \"$(basename $LOGDIR)\", \"parameterFile\" : \"${paramsname}\", \"benchmarkName\" : \"${benchmarkname}\" }"

function clear_up {
	execute "delete_resource_group" az group delete --name "$resource_group" --yes

        timingData=$(cat $LOGDIR/times.csv | jq -s -R 'split("\n") | map(select(. != "")) | map(split(",") | map(select(. != ""))) | map({"event": .[0],"duration": .[1]})')
        jq -c -n '.timing=$data' --argjson data "$timingData" >$LOGDIR/timing.json
        
        jq -c '.' <<< $telemetryData >$LOGDIR/root.json

        # merge all the json data into one see https://stackoverflow.com/questions/19529688/how-to-merge-2-json-file-using-jq
        jq -c -s 'reduce .[] as $item ({}; . * $item)' $LOGDIR/root.json $LOGDIR/singlehpl.json $LOGDIR/stream.json $LOGDIR/timing.json $LOGDIR/ringpingpong.json $LOGDIR/allreduce.json $LOGDIR/benchmark.json $LOGDIR/failure.json >$LOGDIR/telemetry.json

        if [ "$logToStorage" = true ]; then
                $DIR/cosmos_upload_doc.sh "$cosmos_account" "$cosmos_database" "$cosmos_collection" "$cosmos_key" "$LOGDIR/telemetry.json" >$LOGDIR/curl_upload_cosmosdb.result
        fi
}

function check_hanging_nodes {       
        scenario=$1
        jsonFailure=$LOGDIR/failure.json
        tmpJson=$LOGDIR/tmp.json
        # running pdsh 'hostname' will return the failed nodes
        execute "hanging_$scenario" ssh hpcuser@${public_ip} "pdsh -f $PDSH_MAX_CONNECTIONS 'hostname'"
        cat $(get_log "hanging_$scenario") | jq -s -R 'split("\n") | map(select(contains("exited"))) | map(split(":")) | map({"hostname": .[1]|ltrimstr(" ")})' >$tmpJson
        jq -n '.failure.scenario=$scenario | .failure.nodes=$data ' --arg scenario "$scenario" --argfile data $tmpJson >$jsonFailure

        # extract node instance id
        nodes=$(jq -n '.nodes=[]')
        for node in $(jq -r '.failure.nodes[] | .hostname' $jsonFailure); do
                item=$(jq -n '.hostname=$node | .instanceid=$id | .vmssnodename=$vmssName+"_"+$id' --arg node $node --arg vmssName $vmssName --arg id  `./scripts/base36ToDec ${node: -2}`)
                nodes=$(jq '.nodes[.nodes| length] += $data' --argjson data "$item" <<< $nodes)
        done

        jq '.failure+=$nodes' --argjson nodes "$nodes" $jsonFailure > $tmpJson
        cp $tmpJson $jsonFailure

        # get blob logs
        accountname=${vmssName}sa
        sakey=$(az storage account keys list -n ${accountname} -g ${resource_group} | jq -r '.[] | select(.keyName == "key1") | .value')

        for node in $(jq -r '.failure.nodes[] | .instanceid' $jsonFailure); do
                serialLog=$(az vmss get-instance-view  --resource-group $resource_group --name $vmssName --instance-id $node | jq -r '.bootDiagnostics.serialConsoleLogBlobUri')
                container=$(echo $serialLog | cut -d'/' -f4)
                blobname=$(echo $serialLog | cut -d'/' -f5)

                az storage blob download -c $container -f $LOGDIR/$blobname -n $blobname --account-key $sakey  --account-name $accountname 2>&1 > /dev/null || echo "Failed to download blob"
                execute "hanging_${node}" cat $LOGDIR/$blobname                
        done

}


# assuming already logged in a the moment or use the Service Principal params
if [ "$azLogin" != "" ]; then
        echo "login to azure with Service Principal"
        az login --service-principal -u $azLogin -p $azPassword --tenant $azTenant
fi

# make sure the resource group does not exist
if [ "$(az group exists --name $resource_group)" = "true" ]; then
        echo "Error: Resource group already exists"
        exit 1
fi

# create the resource group
execute "create_resource_group" az group create --name "$resource_group" --location "$location" --tags "workload=e2ehpc"
subscriptionId=$(jq '.id' $(get_log "create_resource_group") | cut -d'/' -f3)
telemetryData="$(jq ".subscription=\"$subscriptionId\" | .location=\$data.location | .resourceGroup=\$data.name" --argjson data "$(<$(get_log "create_resource_group"))" <<< $telemetryData)"

parameters=$(cat << EOF
{
        "vmSku": {
                "value": "$vmSku"
        },
        "vmssName": {
                "value": "$vmssName"
        },
        "computeNodeImage": {
                "value": "$computeNodeImage"
        },
        "instanceCount": {
                "value": $instanceCount
        },
        "rsaPublicKey": {
                "value": "$rsaPublicKey"
        }
}
EOF
)

# deploy azhpc
execute "deploy_azhpc" az group deployment create \
    --resource-group "$resource_group" \
    --template-uri "https://raw.githubusercontent.com/$githubUser/azhpc/$githubBranch/azuredeploy.json" \
    --parameters "$parameters"

deploymentTime=$(grep deploy_azhpc $LOGDIR/times.csv | cut -d',' -f2)
errorToDeploy=$(grep "ERROR:" $(get_log "deploy_azhpc") | wc -l)
if [ "$errorToDeploy" = "1" ]; then
        echo "Failed to create VMSS"
        telemetryData="$(jq ".clusterDeployment.status=\"failed\"" <<< $telemetryData)"
        clear_up
        exit 1
fi

telemetryData="$(jq '.vmSize=$data.properties.parameters.vmSku.value | .computeNodeImage=$data.properties.parameters.computeNodeImage.value | .instanceCount=$data.properties.parameters.instanceCount.value | .provisioningState=$data.properties.provisioningState | .deploymentTimestamp=$data.properties.timestamp | .correlationId=$data.properties.correlationId' --argjson data "$(<$(get_log "deploy_azhpc"))" <<< $telemetryData)"
telemetryData="$(jq '.deploymentDuration=$data' --arg data $deploymentTime <<< $telemetryData)"

public_ip=$(az network public-ip list --resource-group "$resource_group" --query [0].dnsSettings.fqdn | sed 's/"//g')

execute "get_vmss_instances" az vmss list-instances --resource-group "$resource_group" --name "$vmssName"
# upload hostlist
jq -r '.[].osProfile.computerName' $(get_log "get_vmss_instances") | ssh hpcuser@${public_ip} 'cat - >bin/hostlist'

# gather syslog and waagent logs
execute "gather_logs" ssh hpcuser@${public_ip} "pdsh 'sudo cat /var/log/messages > messages-\$(hostname) && sudo cat /var/log/waagent.log > waagent-\$(hostname).log'"
get_files 'messages-*' 'waagent*.log'


execute "check_host_status" ssh hpcuser@${public_ip} "pdsh -f $PDSH_MAX_CONNECTIONS 'echo Working'"
working_hosts=$(grep "Working" $(get_log "check_host_status") | wc -l)
if [ "$working_hosts" = "" ]; then
        echo "Failed to get hosts."
        telemetryData="$(jq ".clusterDeployment.status=\"failed\"" <<< $telemetryData)"
        clear_up
        exit 1
fi
retry=1
while [ "$retry" -lt "6" -a "$working_hosts" -ne "$instanceCount" ]; do
        sleep 60
        execute "check_host_status_retry_$retry" ssh hpcuser@${public_ip} "pdsh -f $PDSH_MAX_CONNECTIONS 'echo Working'"
        working_hosts=$(grep "Working" $(get_log "check_host_status_retry_$retry") | wc -l)
        let retry=$retry+1
done

telemetryData="$(jq ".clusterDeployment.sshretries=\"$retry\"" <<< $telemetryData)"

if [ "$working_hosts" -ne "$instanceCount" ]; then
        echo "Error: all hosts are not accessible with ssh."
        telemetryData="$(jq ".clusterDeployment.status=\"failed\"" <<< $telemetryData)"
        clear_up
        exit 1
fi
telemetryData="$(jq ".clusterDeployment.status=\"success\"" <<< $telemetryData)"

execute "show_bad_nodes" ssh hpcuser@${public_ip} testForBadNodes
bad_nodes=$(grep fail $(get_log "show_bad_nodes") | wc -l)
if [ "$bad_nodes" -ne "0" ]; then
        echo "Error: $bad_nodes hosts do not have IB working."
        telemetryData="$(jq ".clusterDeployment.status=\"failed\"" <<< $telemetryData)"
        clear_up
        exit 1
fi

# run the STREAM benchmark
execute "get_stream" ssh hpcuser@${public_ip} 'wget https://paedwar.blob.core.windows.net/public/stream.96GB && chmod +x stream.96GB'
execute "run_stream" ssh hpcuser@${public_ip} pdsh -f $PDSH_MAX_CONNECTIONS 'KMP_AFFINITY=scatter ./stream.96GB'
stream_results=$(cat $(get_log "run_stream") | jq -s -R 'split("\n") | map(select(contains("Triad"))) | map(split(" ") | map(select(. != ""))) | map({"hostname": .[0]|rtrimstr(":"),"triad":.[2]})')
jq -c -n '.stream.results=$data' --argjson data "$stream_results" >$LOGDIR/stream.json

# run the LINPACK benchmark
execute "get_linpack" ssh hpcuser@${public_ip} "wget 'https://pintaprod.blob.core.windows.net/private/hpl.tgz?sv=2016-05-31&si=read&sr=b&sig=5ZluFkKL%2F3GyNexDVQBB1sEmUdHpkutLlXaLfE%2BmUN4%3D' -q -O -  | tar zx --skip-old-files"
execute "run_linpack" ssh hpcuser@${public_ip} "pdsh -f $PDSH_MAX_CONNECTIONS 'cd hpl; mpirun -np 2 -perhost 2 ./xhpl_intel64_static -n $linpack_N -p $linpack_P -q $linpack_Q -nb $linpack_NB | grep WC00C2R2'"
linpack_results="$(cat $(get_log "run_linpack") | jq -s -R 'split("\n") | map(select(contains("WC00C2R2"))) | map(split(" ") | map(select(. != ""))) | map({"hostname": .[0]|rtrimstr(":"),"duration": .[6],"gflops": .[7]})')"
singlehplJson="$(jq -c -n ".singlehpl.parameters={N:$linpack_N, P:$linpack_P, Q:$linpack_Q, NB:$linpack_NB}")"
jq -c '.singlehpl.results=$data' --argjson data "$linpack_results" <<< $singlehplJson >$LOGDIR/singlehpl.json

# run the ring pingpong benchmark
execute "run_ring_pingpong" ssh hpcuser@${public_ip} 'ssh $(head -n1 bin/hostlist) ./azhpc/benchmarks/run_ring_pingpong.sh'
get_files '*_to_*_pingpong.log'
for i in $LOGDIR/*_to_*_pingpong.log; do
        src=$(echo ${i##*/} | cut -d'_' -f1)
        dst=$(echo ${i##*/} | cut -d'_' -f3)
        cat $LOGDIR/${src}_to_${dst}_pingpong.log | grep -A27 'Benchmarking PingPong' | tail -n24 | jq -s -R 'split("\n") | map(select(. != "")) | map(split(" ") | map(select(. != ""))) | map({"src":"'$src'","dst":"'$dst'","bytes":.[0],"repetitions":.[1],"t_usec":.[2],"Mbytes_sec":.[3]})' >$LOGDIR/${src}_to_${dst}_pingpong.json
done
jq -s 'flatten | {"ringpingpong":{"results":.}}' $LOGDIR/*_to_*_pingpong.json >$LOGDIR/ringpingpong.json

# run the allreduce benchmark
exectimeo=300
numberOfProcesses=$(bc <<< "$instanceCount * $processesPerNode")
execute_timeout_duration=300
execute "run_allreduce" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'mpirun -np $numberOfProcesses -ppn $processesPerNode -hostfile \$HOME/bin/hostlist IMB-MPI1 Allreduce -iter 10000 -npmin $numberOfProcesses -msglog 3:4 -time 1000000'"
allreduceData=$(cat $(get_log run_allreduce) | grep -A6 "Benchmarking Allreduce" | tail -n2 | jq -s -R 'split("\n") | map(select(. != "")) | map(split(" ") | map(select(. != ""))) | map({"bytes":.[0],"repetitions":.[1],"t_min_usec":.[2],"t_max_usec":.[3],"t_avg_usec":.[4]})')
jq -c -n '.allreduce.processesPerNode=$processesPerNode | .allreduce.results=$data' --arg processesPerNode $processesPerNode --argjson data "$allreduceData" >$LOGDIR/allreduce.json
if [ "$execute_timeout" = true ]; then
        check_hanging_nodes "allreduce"
        clear_up
        exit 1        
fi

# run the benchmark function
benchmarkData="{}"
run_benchmark
jq -c -n '.benchmark=$data' --argjson data "$benchmarkData" >$LOGDIR/benchmark.json
if [ "$execute_timeout" = true ]; then
        check_hanging_nodes "benchmark"
fi

if [ "$leaveRunning" != true ]; then
        clear_up
fi
