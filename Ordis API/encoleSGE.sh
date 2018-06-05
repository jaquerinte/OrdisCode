#!/bin/bash
#################################
#Script for encole job been 
#other user for apache
#################################
#$1 User
#$2 Proyect
#$3 Filename
#################################
user=$1
proyect=$2
filename=$3


su - $user -c "/opt/gridengine/bin/linux-x64/qsub /export/home/$user/projects/$proyect/$filename"
