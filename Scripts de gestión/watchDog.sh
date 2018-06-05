##########################################################
#WatchDogs Checks process in ordis fo check if 
#job starts, fisish , or crash
# To see progress of a job, a job create files like start, finish.
# if these script see that files, send a msn and change the name to 
# name.send for kwon that this notification whas send  
##########################################################
# Functions
#################
#Parameters for sendEmail
#$1 remote user 
#$2 email
#$3 subject
#$4 text
#$5 textCod
################
function sendEmail {
	php /var/www/html/ordis/EPSLibraries/send.email.php "$1" "$2" "$3" "$4" "$5" > /dev/null 2>&1
}
function log {
	echo $1  >> /export/scripts/maintenance/log.txt
}

#load config file
source /export/scripts/maintenance/watch.conf
# Loop for all users with folder projects
#log "activo"
for f in /export/home/*/projects/* ;do 
	#extract user 
		user=$(echo $f| cut -d'/' -f 4)
	#extract project
		project=$(echo $f| cut -d'/' -f 6)
	#extract mail
		mail=$(cat $f/datos.txt| cut -d'>' -f 2 | sed -e 's/^[ \t]*//')
	#print user:project
	#	echo $user:$project	
	#checks started jobs
		if [ -r $f/start ]; then 
			# a job has start
			#send mail 
				sendEmail $user $mail "Proyecto $project ha comenzado" "El proyecto $project $startText" "ordis"
				log "email for start job sent"
			#change name 
				mv $f/start $f/start.send 
		fi 
	#checks finish jobs
		if [ -r $f/finish ]; then
                	# a job has finish
			
			#change name
                                mv $f/finish $f/finish.send

                        #Prepare data
			#Calculate Hash
				resu=$(echo -n $user$project$(cat $f/end)|sha256sum)
			#Eliminate - and the two spaces 
				resu=${resu%???}
			#tar -czf $f/$resu.tar.gz -C $f .
			#Create Tar with all data in the folder 
				tar --exclude="start.send*" --exclude="finish.send*" --exclude="end*" --exclude="run.sh*" --exclude="datos.txt*"  -czf $f/$resu.tar.gz -C $f .  
			#mv to server 
				mv $f/$resu.tar.gz /ordis 
			#create url gets the url from the watch.conf
				url="$url$resu.tar.gz"
			#send mail
				sendEmail $user $mail "Proyecto $project ha finalizado" "$finishText $url" "ordis"
                        	log "email for finish for user $user to mail $mail job sent" 
        	fi
	




done 
