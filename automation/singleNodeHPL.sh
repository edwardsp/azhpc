required_envvars public_ip

function run_benchmark() {
	execute "get_hpl" ssh hpcuser@${public_ip} "wget 'https://pintaprod.blob.core.windows.net/private/hpl.tgz?sv=2016-05-31&si=read&sr=b&sig=5ZluFkKL%2F3GyNexDVQBB1sEmUdHpkutLlXaLfE%2BmUN4%3D' -q -O -  | tar zx --skip-old-files"
	
	# run HPL. problem size 69120 is allocating 36 GB. For 64GB use 92160.
	# 
    for i in $(seq 1 5); do	
		execute "run_hpl${i}" ssh hpcuser@${public_ip} "pdsh 'cd hpl; mpirun -genv KMP_AFFINITY compact -genv I_MPI_DEBUG 6 -np 2 -perhost 2 ./xhpl_intel64_static -n 69120 -p 1 -q 2 -nb 192 | grep WC00C2R2'"
	done
}
