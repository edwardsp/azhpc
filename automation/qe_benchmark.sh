
function run_benchmark() {
    scratch_dir=/mnt/resource/scratch
    qe_dir=${scratch_dir}/qe

    execute "download_qe" ssh hpcuser@${public_ip} "cd ${scratch_dir} && wget 'https://azcathpcsane.blob.core.windows.net/apps/espresso-5.4.0-impi.tgz?sv=2017-04-17&si=read&sr=c&sig=%2BKP1aEa0ciOyckj11PxDlqoYfiXQKDhDOaJSwkbzCig%3D' -q -O -  | tar zx --skip-old-files"
    execute "download_benchmark_qe" ssh hpcuser@${public_ip} "cd ${qe_dir} && wget 'https://azcathpcsane.blob.core.windows.net/apps/input_qe.tgz?sv=2017-04-17&si=read&sr=c&sig=%2BKP1aEa0ciOyckj11PxDlqoYfiXQKDhDOaJSwkbzCig%3D' -q -O - | tar zx  --skip-old-files"
    
    numProcs=$(bc <<< "$instanceCount * $processesPerNode")

    # set max runtime to 5 hours, but make sure the garbage collection of the RG is not hitting our RG
    # to do so remove the tag workload=e2ehpc from the RG
    execute_timeout_duration=18000
    execute "run_benchmark_qe" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd ${qe_dir}/input && mpirun -np $numProcs -ppn $processesPerNode -genv LD_LIBRARY_PATH ${qe_dir}:\$LD_LIBRARY_PATH -hostfile \$HOME/bin/hostlist ${qe_dir}/pw.x -input pw_1.in'"

# TODO : check what needs to be extracted from the output file
    benchmarkData="{}"
}
