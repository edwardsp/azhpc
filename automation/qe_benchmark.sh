
function run_benchmark() {
    execute "download_qe" ssh hpcuser@${public_ip} "cd /mnt/resource/scratch && wget 'https://azcathpcsane.blob.core.windows.net/apps/espresso-5.4.0-impi.tgz?sv=2017-04-17&si=read&sr=c&sig=%2BKP1aEa0ciOyckj11PxDlqoYfiXQKDhDOaJSwkbzCig%3D' -q -O -  | tar zx --skip-old-files"
    execute "download_benchmark_qe" ssh hpcuser@${public_ip} "cd /mnt/resource/scratch/qe && wget 'https://azcathpcsane.blob.core.windows.net/apps/input_qe.tgz?sv=2017-04-17&si=read&sr=c&sig=%2BKP1aEa0ciOyckj11PxDlqoYfiXQKDhDOaJSwkbzCig%3D' -q -O - | tar zx  --skip-old-files"
    
    numProcs=$(bc <<< "$instanceCount * $processesPerNode")

    execute "run_benchmark_qe" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd /mnt/resource/scratch/qe/input && mpirun -np $numProcs -ppn $processesPerNode -env LD_LIBRARY_PATH /mnt/resource/scratch/qe/\$LD_LIBRARY_PATH -hostfile \$HOME/bin/hostlist ../pw.x -input pw_1.in'"

    benchmarkData="{}"
}
