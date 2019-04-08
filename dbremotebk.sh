#!/bin/bash

# Linux Database Remote Backup Script
# Version: 1.0
# Script by: Yamacasis
# Email: yamacasis@gmail.com


backup_path="/home/dbroot"

create_mysql_backup() {
  umask 177

  FILE="$db_name-$d.sql.gz"
  mysqldump --user=$user --password=$password --host=$host $db_name | gzip --best > $FILE

  echo 'Backup Complete'
}

clean_backup() {
  rm -f $backup_path/$FILE
  echo 'Local Backup Removed'
}

########################
# Configuration        #
########################

# Database credentials
user="root"
password="uQ12!mn2Z"
host="192.168.110.3"
db_name="espard_app"

# FTP Login Data
USERNAME="Esparddb"
PASSWORD="oiWEwqeFSDa12"
SERVER="192.168.140.4"
PORT="21"

#Remote directory where the backup will be placed
REMOTEDIR="./"

#Transfer type
#1=FTP
#2=SFTP
TYPE=1

#Daabase Active
MYSQL=1
MONGO=0

##############################
# Start Backup Script        #
##############################

d=$(date +%F-%H%M%S)
cd $backup_path
create_mysql_backup

if [ $TYPE -eq 1 ]
then
ftp -n -i $SERVER <<EOF
user $USERNAME $PASSWORD
binary
cd $REMOTEDIR
mput $FILE
quit
EOF
elif [ $TYPE -eq 2 ]
then
rsync --rsh="sshpass -p $PASSWORD ssh -p $PORT -o StrictHostKeyChecking=no -l $USERNAME" $backup_path/$FILE $SERVER:$REMOTEDIR
else
echo 'Please select a valid type'
fi

echo 'Remote Backup Complete'
clean_backup
##############################
# End Backup Script          #
##############################
