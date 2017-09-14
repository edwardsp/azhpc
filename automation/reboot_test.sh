
function run_benchmark() {
    rebootLogFile=$(get_log "reboot_failures")
    touch $rebootLogFile
    for reboot in $(seq 1 10); do
        execute "reboot_${reboot}" az vmss restart --name "$vmssName" --resource-group "$resource_group"
        
        execute "reboot_${reboot}_get_hosts" ssh hpcuser@${public_ip} nmapForHosts
        working_hosts=$(sed -n "s/.*sshin=\([^;]*\).*/\1/p" $(get_log "reboot_${reboot}_get_hosts"))
        retry=1
        while [ "$retry" -lt "6" -a "$working_hosts" -ne "$instanceCount" ]; do
            sleep 60
            execute "reboot_${reboot}_get_hosts_retry_$retry" ssh hpcuser@${public_ip} nmapForHosts
            working_hosts=$(sed -n "s/.*sshin=\([^;]*\).*/\1/p" $(get_log "reboot_${reboot}_get_hosts_retry_$retry"))
            let retry=$retry+1
        done

        if [ "$working_hosts" -ne "$instanceCount" ]; then
            echo "Reboot $reboot failed: All hosts are not accessible with ssh" | tee -a $rebootLogFile
            continue
        fi

        execute "reboot_${reboot}_show_bad_nodes" ssh hpcuser@${public_ip} testForBadNodes
        retry=1
        bad_nodes=$(grep fail $(get_log "reboot_${reboot}_show_bad_nodes") | wc -l)
        while [ "$retry" -lt "6" -a "$bad_nodes" -ne "0" ]; do
            sleep 60
            execute "reboot_${reboot}_show_bad_nodes_retry_$retry" ssh hpcuser@${public_ip} testForBadNodes
            bad_nodes=$(grep fail $(get_log "reboot_${reboot}_show_bad_nodes_retry_$retry") | wc -l)
            let retry=$retry+1
        done

        if [ "$bad_nodes" -ne "0" ]; then
            echo "Reboot $reboot failed: $bad_nodes bad nodes." | tee -a $rebootLogFile
            continue
        fi
    done
}