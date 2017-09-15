#!/bin/bash

function required_envvars {
        condition_met=true
        for i in "$@"; do
        if [ -z "$i" ]; then
                        echo "ERROR: $i needs to be set."
                        condition_met=false
                else
                        echo "$i=${!i}"
                fi
        done
        if [ "$condition_met" = "false" ]; then
                echo
                exit 1
        fi
}

# a variable to store the last duration for the execute call
execute_duration=0

function execute {
        task=$1
        SECONDS=0
        echo -n "Executing: $2"
        for a in "${@:3}"; do
                echo -n " '$(echo -n $a | tr '\n' ' ')'"
        done
        echo
        $2 "${@:3}" 2>&1 | tee $LOGDIR/${task}.log
        execute_duration=$SECONDS
        echo "$task $execute_duration" | tee -a $LOGDIR/times.log

        if [ "$logToStorage" = true ]; then
                az storage blob upload \
                        --account-name $logStorageAccountName \
                        --container-name $logStorageContainerName \
                        --file $LOGDIR/$task.log \
                        --name $logStoragePath/$LOGDIR/$task.log \
                        --sas "$logStorageSasKey"
                az storage blob upload \
                        --account-name $logStorageAccountName \
                        --container-name $logStorageContainerName \
                        --file $LOGDIR/times.log \
                        --name $logStoragePath/$LOGDIR/times.log \
                        --sas "$logStorageSasKey"
        fi
}

function get_files {
        for fname in "$@"; do
                scp hpcuser@${public_ip}:$fname $LOGDIR
        done
}

function get_log {
	task=$1
	echo $LOGDIR/${task}.log
}
