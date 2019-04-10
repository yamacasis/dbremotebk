#!/bin/bash

# Linux Database Remote Backup Script
# Version: 1.0
# Script by: YamaCasis
# Email: yamacasis@gmail.com
# Created : 8 April 2019

########################
# Configuration        #
########################

. config.conf

########################
# Functions            #
########################

create_mysql_backup() {
  umask 177

  FILE="$s-$d.sql.gz"
  $MYSQLDUMP_path --user=$MYSQL_user --password=$MYSQL_password --host=$MYSQL_host $s | gzip --best > $FILE

  MSG="----> Mysql backup Database $S : $d : $FILE "
  echo $MSG

  if [ $LOGSTATE -eq 1 ]
  then
    log_it $MSG
  fi

}

create_mongo_backup() {
  umask 177

  FILE="mongo-$s-$d"
  if [ -z  "$MONGO_user"]
  then
    CERT=""
  else
    CERT=" --username $MONGO_user --password $MONGO_password "
  fi
  $MYSQLDUMP_path --host $MONGO_host -d $s $CERT --out $FILE
  tar -zcf $FILE.tar.gz $FILE
  rm -rf $FILE
  FILE="$FILE.tar.gz"

  MSG="----> Mongo backup Database $S : $d : $FILE "
  echo $MSG

  if [ $LOGSTATE -eq 1 ]
  then
    log_it $MSG
  fi

}

clean_backup() {
  rm -f $backup_path/$FILE

  MSG="---- |__ Clear backup File : $backup_path/$FILE "
  echo $MSG

  if [ $LOGSTATE -eq 1 ]
  then
    log_it $MSG
  fi
}

send_backup() {
  if [ $TYPE -eq 1 ]
  then
    ftp -n -i $SERVER <<EOF
    user $USERNAME $PASSWORD
    binary
    cd $REMOTEDIR
    mput $FILE
    quit
EOF

    MSG="---- |__ Send backup File (FTP): $FILE "
    echo $MSG
    if [ $LOGSTATE -eq 1 ]
    then
      log_it $MSG
    fi

  elif [ $TYPE -eq 2 ]
  then
    rsync --rsh="sshpass -p $PASSWORD ssh -p $PORT -o StrictHostKeyChecking=no -l $USERNAME" $backup_path/$FILE $SERVER:$REMOTEDIR

    MSG="---- |__ Send backup File (SFTP): $FILE "
    echo $MSG
    if [ $LOGSTATE -eq 1 ]
    then
      log_it $MSG
    fi
  else
    MSG="---- |__ Dont Send"
    echo $MSG
  fi
}

log_it() {
    today="$(date +'%Y%m%d')";
    logfile=$DIR'/logs/'$today'.log'
    if [ -e $logfile ]
    then
      echo '   ' >> $logfile;
    else
    	echo '' > $logfile;
    fi

    echo $1 >> $logfile;
}

##############################
# Start Backup Script        #
##############################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $backup_path

d=$(date +%F-%H:%M:%S)
MSG="+ Start script ( $d ) : "
echo $MSG

if [ $LOGSTATE -eq 1 ]
then
  log_it $MSG
fi

if [ $MYSQL -eq 1 ]
then
  for s in "${MYSQL_dbs_name[@]}";
  do
    d=$(date +%F-%H:%M:%S)

    create_mysql_backup

    send_backup

    if [ $DELE -eq 1 ]
    then
      clean_backup
    fi
  done
fi

if [ $MONGO -eq 1 ]
then
  for s in "${MONGO_dbs_name[@]}";
  do
    d=$(date +%F-%H:%M:%S)

    create_mongo_backup

    send_backup

    if [ $DELE -eq 1 ]
    then
      clean_backup
    fi
  done
fi

d=$(date +%F-%H:%M:%S)
MSG="+ Ended script ( $d ) ;  "
echo $MSG

if [ $LOGSTATE -eq 1 ]
then
  log_it $MSG
fi

##############################
# End Backup Script          #
##############################
