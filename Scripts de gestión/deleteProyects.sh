#!/bin/bash
#####################################################
#Script for delete projects order than 2 weeks or
#not been updated for 2 weeks
#also delete tgz more old than 2 weeks
#####################################################
#Max time for last modify
maxTime=1209600
maxTimeTGZ=1209600
#see all projects in ordis
for f in /export/home/*/projects/* ;do
        #extract data for time actual and less from last modfy of file datos.txt
        if [ -r $f/datos.txt ]; then
                time=$(($(date +%s) - $(stat  -c %Y $f/datos.txt)))
                #echo "$time"
                #if the time is more or equal to two weeks delete folder
                if [ "$time" -ge "$maxTime" ]; then
                        echo "borrado $f"
                        rm -rf $f
                fi
        fi
done

for compress in /ordis/* ;do
        #extract data for time actual and less from life of tgz file
        time=$(($(date +%s) - $(stat  -c %Y $compress)))
        #echo "$time"
        #echo "$compress"
        #if the time is mor or equal to two weeks delete folder
         if [ "$time" -ge "$maxTimeTGZ" ]; then
                        echo "borrado $f"
                        rm -f $compress
                fi
done