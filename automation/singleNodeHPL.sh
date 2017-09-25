required_envvars vmSku

function run_benchmark() {
	execute "get_hpl" ssh hpcuser@${public_ip} "wget 'https://pintaprod.blob.core.windows.net/private/hpl.tgz?sv=2016-05-31&si=read&sr=b&sig=5ZluFkKL%2F3GyNexDVQBB1sEmUdHpkutLlXaLfE%2BmUN4%3D' -q -O -  | tar zx --skip-old-files"
	
	scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	hplParams=$(jq '.singleNode[] | select(.vmSize == $data)' --arg data $vmSku $scriptdir/hplparams.json)
	N=$(jq '.N' <<< $hplParams)
	NB=$(jq '.NB' <<< $hplParams)
	P=$(jq '.P' <<< $hplParams)
	Q=$(jq '.Q' <<< $hplParams)
	
	# run HPL
	# 
    for i in $(seq 1 5); do	
		execute "run_hpl${i}" ssh hpcuser@${public_ip} "pdsh 'cd hpl; mpirun -np 2 -perhost 2 ./xhpl_intel64_static -n $N -p $P -q $Q -nb $NB | grep WC00C2R2'"
	done

	jsonRoot="$(jq -n '.singlehpl=$data | .singlehpl.results=[]' --argjson data "$hplParams")"

	#jsonRoot="$(jq -n '.singlehpl.parameters.N=69120 | .singlehpl.parameters.P=1 | .singlehpl.parameters.Q=2 | .singlehpl.parameters.NB=192 | .singlehpl.results=[]' )"
	json="$(cat $LOGDIR/run_hpl*.log | jq -s -R 'split("\n") | map(select(contains("WC00C2R2"))) | map(split(" ") | map(select(. != ""))) | map({"hostname": .[0]|rtrimstr(":"),"duration": .[6],"gflops": .[7]})')"
	benchmarkData="$(jq '.singlehpl.results=$data' --argjson data "$json" <<< $jsonRoot)"
}
