###############################################################
# Script for add user to the system using apache
###############################################################
#$1 User name 
#
###############################################################

if [ "$1" == ""  ];  then
                echo "ERROR NEED USERNAME"
                exit
        fi
# Create user
sudo useradd $1 -g projects -m -k /etc/ordisSkel
#sync user with database of ordis
sudo /opt/rocks/bin/rocks sync users &> /dev/null & 
