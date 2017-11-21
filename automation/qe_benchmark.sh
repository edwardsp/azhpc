
function run_benchmark() {
    execute "download_qe" ssh hpcuser@${public_ip} "wget 'https://azcathpcsane.blob.core.windows.net/apps/espresso-5.4.0-impi.tgz?sv=2017-04-17&si=read&sr=c&sig=%2BKP1aEa0ciOyckj11PxDlqoYfiXQKDhDOaJSwkbzCig%3D' -q -O -  | tar zx --skip-old-files"
    execute "download_benchmark_qe" ssh hpcuser@${public_ip} "cd qe && wget 'https://azcathpcsane.blob.core.windows.net/apps/input_qe.tgz?sv=2017-04-17&si=read&sr=c&sig=%2BKP1aEa0ciOyckj11PxDlqoYfiXQKDhDOaJSwkbzCig%3D' -q -O - | tar zx  --skip-old-files"
    
    numProcs=$(bc <<< "$instanceCount * $processesPerNode")

    execute "run_benchmark" ssh hpcuser@${public_ip} "ssh \$(head -n1 bin/hostlist) 'cd qe/input && mpirun -np $numProcs -ppn $processesPerNode -hostfile \$HOME/bin/hostlist pw.x -input pw_1.in'"

    benchmarkData="{}"
}
