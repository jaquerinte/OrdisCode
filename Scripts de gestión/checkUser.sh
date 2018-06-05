#!/bin/bash
################################################
#Checks if an user given exists and if not 
#Call addUserOrdis.sh
################################################
#$1 username
################################################
if [ "$(getent passwd $1)" == "" ]; then
	#User not exist, call addUserOrdis.sh
	/export/scripts/maintenance/addUserOrdis.sh $1
	exit
fi
	#User exist,Do not do anything
