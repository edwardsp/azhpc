#!/bin/bash
required_envvars LOGDIR
telemetry_file=$LOGDIR/telemetry.json
tmp_telemetry_file=$LOGDIR/tmp.telemetry.json
merged_telemetry=$LOGDIR/merged.telemetry.json

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
    jsonData="{\"vmSize\":\"${vmSize}\", \"computeNodeImage\":\"${computeNodeImage}\", \
               \"instanceCount\":\"${instanceCount}\", \"provisioningState\":\"${provisioningState}\", \
               \"deploymentTimestamp\":\"${deploymentTimestamp}\" }"

    jq -n '.vmSize=$data.vmSize | .computeNodeImage=$data.computeNodeImage | .instanceCount=$data.instanceCount | .provisioningState=$data.provisioningState | .deploymentTimestamp=$data.deploymentTimestamp' --argjson data "${jsonData}" | tee $tmp_telemetry_file

    jq -S -s add $tmp_telemetry_file $telemetry_file | tee $merged_telemetry
    cp $merged_telemetry $telemetry_file
}


# append a json fragment to the telemetry 
# $1 : json fragment
function json.appendFragment()
{
    jsonfragment=$1
    
}