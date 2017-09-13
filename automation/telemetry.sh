#!/bin/bash
required_envvars LOGDIR
telemetry_file=$LOGDIR/telemetry.json
tmp_telemetry_file=$LOGDIR/tmp.telemetry.json

# retrieve azure subscription, location and resource group from the create resource group output
# $1 : log file
function kpi.create_root()
{
    logs=$1   

json=$(cat << EOF
{
    "id":"$(uuidgen)",
    "subscription":"$(jq '.id' $logs | awk -F[/] '{print $3}')",
    "location":$(jq '.location' $logs),
    "resourceGroup":$(jq '.name' $logs)
}
EOF
)

    echo $json > $telemetry_file
    
}

# retrieve vmsize, OS, instanceCount, provision status and time, timestamp from the deploy template output
# $1 : log file
function kpi.update_environment()
{
    logs=$1
    vmSize=$(jq -r '.properties.parameters.vmSku.value' $logs)
    computeNodeImage=$(jq -r '.properties.parameters.computeNodeImage.value' $logs)
    instanceCount=$(jq -r '.properties.parameters.instanceCount.value' $logs)
    provisioningState=$(jq -r '.properties.provisioningState' $logs)
    deploymentTimestamp=$(jq -r '.properties.timestamp' $logs)

    jq --arg data "$vmSize" '.vmSize=$data' $telemetry_file | tee $tmp_telemetry_file
    cp $tmp_telemetry_file $telemetry_file
    jq --arg data "$computeNodeImage" '.computeNodeImage=$data' $telemetry_file | tee $tmp_telemetry_file
    cp $tmp_telemetry_file $telemetry_file
    jq --arg data "$instanceCount" '.instanceCount=$data' $telemetry_file | tee $tmp_telemetry_file
    cp $tmp_telemetry_file $telemetry_file
    jq --arg data "$provisioningState" '.provisioningState=$data' $telemetry_file | tee $tmp_telemetry_file
    cp $tmp_telemetry_file $telemetry_file
    jq --arg data "$deploymentTimestamp" '.deploymentTimestamp=$data' $telemetry_file | tee $tmp_telemetry_file
    cp $tmp_telemetry_file $telemetry_file
    
}


# append a json fragment to the telemetry 
# $1 : json fragment
function json.appendFragment()
{
    jsonfragment=$1
    
}