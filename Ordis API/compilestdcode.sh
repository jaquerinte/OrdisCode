#!/bin/bash
#################################################################
#This script is for compile all types of code  
################################################################
################################################################
# $1 Username in the system
# $2 Name of folder in the user given folder
# $3 Email of the user 
# $4 Type of code if goes to cpu or gpu
# $5 Type of paralelims mpi or other
# $6 Priority of the job
# $7 N of nodes need
################################################################
user=$1
proyect=$2
email=$3
type=$4
typep=$5
priority=$6
nodes=$7


#funcion to wait file 
function waitLock {
while [ -f "/export/home/.lock" ]
        do
	#	echo "sleeping" 
         	sleep 2m
        done
}
#function check if I lock 
function lock {
locket=0
while [ $locket -eq 0 ]
	do
	#trys to copy 
		cp /export/home/"$user"/projects/"$proyect"/.lock /export/home/ -n
	#checks if I sucess lock
	if [  "$(cat /export/home/.lock | grep "$user""$proyect")" != "" ]; then
		locket=1 
	else
		waitLock
	fi
	done
}
#function to create run.sh file PARAM first argument, second namfile
function createRunfile {
	namefile=$2
	#Create run.sh	
	echo "#!/bin/bash" > "$namefile"
	#Add default config for SGE
	echo "#$ -V" >> "$namefile"
	echo "#$ -N $user$proyect" >> "$namefile"
	echo "#$ -wd /export/home/$user/projects/$proyect/" >> "$namefile"
	echo "#$ -j y" >> "$namefile"
	echo "#$ -S /bin/bash" >> "$namefile"
	echo "#$ -p $priority" >> "$namefile"
	#Switch between mpi or other
	if [ "$typep" == "mpi" ]; then
		echo "#$ -pe orte $nodes" >> "$namefile"
	fi
	#Switch between cpu or gpu 
	if [ "$type" == "gpu" ]; then
		echo "#$ -q gpu.q" >> "$namefile"
		echo "#$ -hard -l gpu=1" >> "$namefile"
	fi 
	#if is mpi change script to run other default
	#Add starfile for know when starts the job
	echo "echo \$(date +%k_%M_%m_%d_%y) > start " >> "$namefile"
	# add to the top of the exit file the pararm options
	echo "echo \"Param options: $1\"" >> "$namefile"
	#check types
	 if [ "$typep" == "mpi" ]; then
		echo "mpirun -np $nodes  $filename $1" >> "$namefile"
	else
                echo "$filename $1" >> "$namefile"
               	
	fi
	#Add end file for know when finish
	echo "echo \$(date +%k_%M_%m_%d_%y) > finish " >> "$namefile"
	#Add time in milisecods for use of the sha256
	echo "echo \$(date +%s%N) > end " >> "$namefile"
	chown "$user":projects ./"$filename"
	chown "$user":projects ./"$namefile"
	chmod 775 ./"$namefile"

}


#Checks than an user has been given 
	if [ "$user" == ""  ];	then 
		echo "ERROR NEED USERNAME"
		exit
	fi
#Checks than a forder has been given
	if [ "$proyect" == ""  ];  then
                echo "ERROR NEED PROYECTNAME"
                exit
        fi
#Checks than a email has been given
        if [ "$proyect" == ""  ];  then
                echo "ERROR NEED AN EMAIL"
                exit
        fi
#Checks than a type has been given if not puts cpu
        if [ "$type" == ""  ];  then
                type="cpu"
        fi
#Checks than a type of paralesim has been given if not puts other
        if [ "$typep" == ""  ];  then
                typep="other"
        fi
#Checks than a number of nodes has been given if not puts 1
        if [ "$nodes" == ""  ];  then
                nodes="1"
        fi
#Checks than a priority has been given if not puts 0
        if [ "$priority" == ""  ];  then
                priority="0"
        fi
#Checks than an user exits 	
	if [ "$(getent passwd "$user")" == "" ]; then 
		echo "ERROR USER NOT EXITS"
		exit
	fi
#Checks than a folder exist
	if [ ! -d "/export/home/$user/projects/$proyect" ]; then
  		echo "ERROR FOLDER NOT EXIST"
		exit
	fi
#Compile Code in the folder
	cd /export/home/"$user"/projects/"$proyect" || exit
#Checks makefile
	if [ ! -f "/export/home/$user/projects/$proyect/makefile" ]; then
                echo "ERROR MAKEFILE DON'T EXIST"
                exit
        fi
#Create the .lock file for this build
	echo "$user$proyect" > .lock
#check if locket
	lock
#Compile	
#set enviromental variables 
#LD_lib and mpi
export PATH=$PATH:/opt/gridengine/lib/linux-x64:/opt/openmpi/lib:/export/library/:/opt/python/lib:/opt/openmpi/bin
# CUDA
export PATH=$PATH:/usr/local/cuda-8.0/include/:/usr/local/cuda-8.0/bin/
#Get bin name
	make &> result &
#waits until make getiing the PID finish 
	wait "$(ps | grep 'make' |awk '{print $1}')"
#Check errors makefile
	if [ "$(cat result | grep error)" == "" ] && [ "$(cat result | grep Error)" == "" ]; then
		#filename=$(gawk -F' ' '{ print $3 }' ./result | grep -v  "\-o")
		filename=$(find . -exec file {} \; | grep executable |cut -d: -f1)
		rm ./result ./*.o -f
	else
		echo "ERROR IN COMPILATION"
		#Send Error
		#eliminate lock
		rm /export/home/.lock 
	exit
	fi   
#elimitate the lock
rm /export/home/.lock
# check if param.txt exits
if [ -a /export/home/"$user"/projects/"$proyect"/param.txt ]; then
	# file exists count number of lines
	lines=$(cat /export/home/"$user"/projects/"$proyect"/param.txt | wc -l)
	# loop for all param lines
	for ((c=1; c<=lines; c++));
	do
		# call to create run.sh file
		param=$(sed "$c q;d" /export/home/"$user"/projects/"$proyect"/param.txt)
		createRunfile "$param" "run_$c.sh"
		#encole job
		sudo /export/scripts/compile/encoleSGEJob.sh "$user" "$proyect" "run_$c.sh"
	done
else	
	# call to create run.sh file without param
	createRunfile "" "run.sh"
	#encole job
	sudo /export/scripts/compile/encoleSGEJob.sh "$user" "$proyect" "run.sh"
fi

###########################################################
# END
###########################################################
