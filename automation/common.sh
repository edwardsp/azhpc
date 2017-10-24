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
execute_timeout=false
execute_timeout_duration_default=1800
execute_timeout_duration=$execute_timeout_duration_default

function execute {
        task=$1
	execute_timeout=false
        SECONDS=0
        echo -n "Executing: $2"
        for a in "${@:3}"; do
                echo -n " '$(echo -n $a | tr '\n' ' ')'"
        done
        echo
	timeout $execute_timeout_duration $2 "${@:3}" >$LOGDIR/${task}.log 2>&1 
	if (($? >= 124))
	then
                echo "Timeout during execution" | tee -a $LOGDIR/${task}.log
                execute_timeout=true
	fi
        
        execute_duration=$SECONDS
        echo "$task,$execute_duration" | tee -a $LOGDIR/times.csv

        upload_blob $task.log
        upload_blob times.csv

        execute_timeout_duration=$execute_timeout_duration_default
}


function error_message {
        echo "ERROR: $1" | tee $LOGDIR/error.log

        upload_blob error.log
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
                        scp -q hpcuser@${public_ip}:$fullpath $LOGDIR
                        upload_blob $fname
                done
        done
}

function upload_blob {
        fname=$1

        if [ "$logToStorage" = true ]; then
                az storage blob upload \
                        --account-name $logStorageAccountName \
                        --container-name $logStorageContainerName \
                        --file $LOGDIR/$fname \
                        --name $logStoragePath/${LOGDIR##*/}/$fname \
                        --sas "$logStorageSasKey" \
                        2>&1 > /dev/null || echo "Failed to upload blob"
        fi

}


function get_log {
	task=$1
	echo $LOGDIR/${task}.log
}