#!/bin/bash

# Linux Database Remote Backup Script
# Version: 1.0
# Script by: YamaCasis
# Email: yamacasis@gmail.com
# Created : 8 April 2019

########################
# Configuration        #
########################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. "$DIR/"config.conf

########################
# Functions            #
########################

create_mysql_backup() {
  umask 177

  PFIX="$(date +'%Y%m%d%H%M%S')";
  FILE="$s-$PFIX.sql.gz"
  $MYSQLDUMP_path --user=$MYSQL_user --password=$MYSQL_password --host=$MYSQL_host $s | gzip --best > $FILE


   fileskb=`du -k "$FILE" | cut -f1`
	if [ $fileskb -gt 0 ]
         then
                 MSG="----> Mysql backup Database $S : $d : $FILE "
         else
	         MSG="----> Mysql backup Database Failed $S : $d : $FILE "
         fi

  echo $MSG

  if [ $LOGSTATE -eq 1 ]
  then
    log_it "$MSG"
  fi

}

create_mongo_backup() {
  umask 177

  FILE="$s"
  if [ -z  "$MONGO_user"]
  then
    CERT=""
  else
    CERT=" --username $MONGO_user --password $MONGO_password "
  fi
  PFIX="-$(date +'%Y%m%d%H%M%S')";
  $MONGODUMP_path --host $MONGO_host -d $s $CERT --out $backup_path
  tar zcf ''$FILE$PFIX'.tar.gz' $backup_path'/'$FILE'/'
  rm -rf $FILE

  FILE="$FILE$PFIX.tar.gz"

  fileskb=`du -k "$FILE" | cut -f1`
  if [ $fileskb -gt 0 ]
	then
		MSG="----> Mongo backup Database $S : $d : $FILE "
	else
		MSG="----> Mongo backup Database Failed $S : $d : $FILE "
	fi
  echo $MSG

  if [ $LOGSTATE -eq 1 ]
  then
    log_it "$MSG"
  fi

}

clean_backup() {
  if [ $KEEPLB -eq 0 ]
  then
	rm -f $backup_path/$FILE
  fi

  find $s-*.gz ! -name "$FILE" -type f -exec rm -f {} +
  MSG="---- |__ Clear backup File  "
  echo $MSG

  if [ $LOGSTATE -eq 1 ]
  then
    log_it "$MSG"
  fi
}

send_backup() {
  if [ $TYPE -eq 1 ]
  then

    ftp -ni $SERVER <<EOF
	user $USERNAME $PASSWORD
	mls  $s-*.gz list.txt
	quit
EOF
    ALLRemote="$(cat list.txt | wc -l)";
nl='
' # yeah, nl is a newline in single quotes
    counter=0
    dellist=''
    KNumber=$((ALLRemote-REMOTEKEEP))
    while IFS= read  -r N
    do

     if [ $counter -le $KNumber ]
     then
     	dellist=$dellist"mdel $N$nl"
     else
	echo "KEEP  : $N"
     fi
     counter=$((counter+1))

    done <list.txt

    ftp -n -i $SERVER <<EOF
    user $USERNAME $PASSWORD
    binary
    cd $REMOTEDIR
    $dellist
    mput $FILE
    quit
EOF

    MSG="---- |__ Send backup File (FTP): $FILE "
    echo $MSG
    if [ $LOGSTATE -eq 1 ]
    then
      log_it "$MSG"
    fi

  elif [ $TYPE -eq 2 ]
  then
    rsync --rsh="sshpass -p $PASSWORD ssh -p $PORT -o StrictHostKeyChecking=no -l $USERNAME" $backup_path/$FILE $SERVER:$REMOTEDIR

    MSG="---- |__ Send backup File (SFTP): $FILE "
    echo $MSG
    if [ $LOGSTATE -eq 1 ]
    then
      log_it "$MSG"
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
	echo $1$2
}

##############################
# Start Backup Script        #
##############################

cd $backup_path

d=$(date +%F-%H:%M:%S)
MSG="+ Start script ( $d ) : "
echo $MSG

if [ $LOGSTATE -eq 1 ]
then
  log_it "$MSG"
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
  log_it "$MSG"
fi

##############################
# End Backup Script          #
##############################
