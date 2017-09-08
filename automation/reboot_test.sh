
function run_benchmark() {
    for reboot in $(seq 1 10); do
        execute "reboot_${reboot}" az vmss restart --name "$vmssName" --resource-group "$resource_group"
        
        execute "reboot_${reboot}_get_hosts" ssh hpcuser@${public_ip} nmapForHosts
        working_hosts=$(grep "Found" $(get_log "reboot_${reboot}_get_hosts") | cut -d' ' -f2)
        retry=1
        while [ "$retry" -lt "6" -a "$working_hosts" -ne "$instanceCount" ]; do
            sleep 60
            execute "reboot_${reboot}_get_hosts_retry_$retry" ssh hpcuser@${public_ip} nmapForHosts
            working_hosts=$(grep "Found" $(get_log "reboot_${reboot}_get_hosts_retry_$retry") | cut -d' ' -f2)
            let retry=$retry+1
        done

        if [ "$working_hosts" -ne "$instanceCount" ]; then
            echo "Error: all hosts are not accessible with ssh."
            clear_up
        fi

        execute "reboot_${reboot}_show_bad_nodes" ssh hpcuser@${public_ip} testForBadNodes
    done
}