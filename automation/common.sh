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
        echo "$task,$execute_duration" | tee -a $LOGDIR/times.csv

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
                        --file $LOGDIR/times.csv \
                        --name $logStoragePath/$LOGDIR/times.csv \
                        --sas "$logStorageSasKey"
        fi
}

function error_message {
        echo "ERROR: $1" | tee $LOGDIR/error.log
        if [ "$logToStorage" = true ]; then
                az storage blob upload \
                        --account-name $logStorageAccountName \
                        --container-name $logStorageContainerName \
                        --file $LOGDIR/times.log \
                        --name $logStoragePath/$LOGDIR/error.log \
                        --sas "$logStorageSasKey"
        fi
}

function get_files {
        for param in "$@"; do
                for fullpath in $(ssh hpcuser@${public_ip} "for i in $param; do if [ -f \"\$i\" ]; then echo \$i; fi; done"); do 
                        fname=${fullpath##*/}
                        echo "Downloading remote file $fullpath to $LOGDIR/$fname."
                        if [ -e "$LOGDIR/$fname" ]; then
                                error_message "get_files: Not getting file $fullpath as it will overwrite local file ($LOGDIR/$fname)"
                                continue
                        fi
                        scp hpcuser@${public_ip}:$fullpath $LOGDIR
                        if [ "$logToStorage" = true ]; then
                                az storage blob upload \
                                        --account-name $logStorageAccountName \
                                        --container-name $logStorageContainerName \
                                        --file $LOGDIR/$fname \
                                        --name $logStoragePath/$LOGDIR/$fname \
                                        --sas "$logStorageSasKey"
                        fi
                done
        done
}

function get_log {
	task=$1
	echo $LOGDIR/${task}.log
}
