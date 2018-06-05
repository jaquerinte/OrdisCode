SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
HOME=/

# For details see man 4 crontabs

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
#for start and stop ordis
  00 23 *  *  fri root /export/scripts/start/start.sh;
  55 23 *  *  sun root /export/scripts/stop/shutdownNodes.sh;
  30 23 *  *  sun root /export/scripts/stop/holdLastWorks.sh
#for checks works
 */5 *  *  *  *    root /export/scripts/maintenance/watchDogOrdis.sh
 0   1  *  *  *    root /export/scripts/maintenance/deleteProjects.sh