#!/bin/bash
#script for start ordis nodes
###########################################
#steps
###########################################
# first send wake on lan signal 
# wait 5 minutes
# check nodes up and down
# if one or more are down wait anoder 5 minutes  -> still down: send email to administrators ->OK: continue
# if not: start NFS
# change state of grafics cards
# Read jobs file 
# encole jobs
###########################################
#code
##########################################

#T1="$(/opt/rocks/bin/rocks run host compute "./" | grep "down" > salida.txt)"

function wait {
	sleep 5m
}
 
#wake on lan 
/export/scripts/start/startNodesAux.sh
#wait 5 minutes 
wait
#check nodes 
#launche test an save result in ./salida.txt
T1="$(/opt/rocks/bin/rocks run host compute "./" | grep "down" > salida.txt)"
#checking up nodes
fail=0
while read p; do
	if [ "$p" != "" ]; then 
		fail=$((fail+1))
	fi
done < salida.txt
if [ "$fail"  == "0"  ]; then
	#true
	echo "ok" >> "/export/logs/log$(date +%k_%M_%m_%d_%y).txt"
else
	#false
	#wake on lan again
	/export/home/jaquer/scripts/start/startNodes.sh
	wait
	#check again
	$T1
	#fail to 0
	fail=0
	#read file
	while read p; do
		if [ "$p" != "" ]; then
        		fail=$((fail+1))
		fi
	done < salida.txt
	if [ "$fail"  != "0"  ]; then
		#still down
		echo "error" >> "/export/logs/log$(date +%k_%M_%m_%d_%y).txt"
        	echo "Nodos Afectados:">> "/export/logs/log$(date +%k_%M_%m_%d_%y).txt"
        	echo $fail >> "/export/logs/log$(date +%k_%M_%m_%d_%y).txt" 
		cat salida.txt >> "/export/logs/log$(date +%k_%M_%m_%d_%y).txt"
		#send email
		cat "/export/logs/log$(date +%k_%M_%m_%d_%y).txt" |mail -s "error" "ivanrodriguezferrandez@gmail.com" #change for final 
		rm ./salida.txt
	else
		echo "ok" >> "/export/logs/log$(date +%k_%M_%m_%d_%y).txt"
		rm ./salida.txt
	fi
	
fi
#start NFS
/export/home/jaquer/scripts/start/exportFolder.sh
#change state of grafic card
/opt/rocks/bin/rocks run host compute 'nvidia-smi -c 1' &>/dev/null
#first un hold all jobs
/opt/gridengine/bin/linux-x64/qrls -u "*"
