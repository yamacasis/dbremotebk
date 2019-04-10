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

  echo "Mysql $s : $FILE - Backup Complete"

  if [ $LOGSTATE -eq 1 ]
  then
    log_it "---- Mysql backup Database $S : $d : $FILE "
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

  echo "Mongo $s : $FILE - Backup Complete"

  if [ $LOGSTATE -eq 1 ]
  then
    log_it "---- Mongo backup Database $S : $d : $FILE "
  fi

}

clean_backup() {
  rm -f $backup_path/$FILE
  echo 'Local Backup Removed'

  if [ $LOGSTATE -eq 1 ]
  then
    log_it "---- Clear backup File : $backup_path/$FILE "
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
    echo "Sended FTP - $FILE"
    if [ $LOGSTATE -eq 1 ]
    then
      log_it "---- Send backup File (FTP): $FILE "
    fi

  elif [ $TYPE -eq 2 ]
  then
    rsync --rsh="sshpass -p $PASSWORD ssh -p $PORT -o StrictHostKeyChecking=no -l $USERNAME" $backup_path/$FILE $SERVER:$REMOTEDIR
    echo "Sended SFTP - $FILE"

    if [ $LOGSTATE -eq 1 ]
    then
      log_it "---- Send backup File (SFTP): $FILE "
    fi
  else
    echo "Dont Send"
  fi
}

log_it() {
    today="$(date +'%Y%m%d')";
    logfile='logs/'$today'.log'
    echo $1 >> $logfile;
}

##############################
# Start Backup Script        #
##############################

cd $backup_path

echo 'Remote Backup ,Starting ...'

if [ $LOGSTATE -eq 1 ]
then
  d=$(date +%F-%H:%M:%S)
  log_it "+ Start script ( $d ) : "
fi

if [ $MYSQL -eq 1 ]
then
  for s in "${MYSQL_dbs_name[@]}";
  do
    d=$(date +%F-%H:%M:%S)
    echo $s
    echo $d

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
    echo $s
    echo $d

    create_mongo_backup

    send_backup

    if [ $DELE -eq 1 ]
    then
      clean_backup
    fi
  done
fi

echo 'Remote Backup Complete'

if [ $LOGSTATE -eq 1 ]
then
  d=$(date +%F-%H:%M:%S)
  log_it "+ Ended script ( $d ) ;  "
fi

##############################
# End Backup Script          #
##############################
