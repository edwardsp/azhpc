required_envvars vmSku

function run_benchmark() {
	execute "get_hpl" ssh hpcuser@${public_ip} "wget 'https://ninalogs.blob.core.windows.net/application/hpl.tgz?sv=2017-04-17&ss=bfqt&srt=sco&sp=rw&se=2027-09-27T10:07:48Z&st=2017-09-27T02:07:48Z&spr=https&sig=IXNV8%2B2mGTuWoRvn5ZcHpdzY9MtEeqN8ootSz%2BLez2w%3D' -q -O -  | tar zx --skip-old-files"
	
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
