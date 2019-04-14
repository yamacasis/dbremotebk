# Linux Database Remote Backup Script

## Requierments

ftp command (FTP send) , rsync  (SFTP send) 


## Instalation


1.Clone Code 

2.Copy config.sample.conf to config.conf

3.Create backup directorie and put path into config file

4.Change your config in config.conf

5.Run code ./dbremotebk.sh or vuild cron


## Config Parameters

|                |Describtion                          |Sample                         |
|----------------|-------------------------------|-----------------------------|
|backup_path	|local backup directorie            |"/home/dbbackup"           |
| Mysql Databases credentials          |mysql username,password,host (if you need mysql database backup)            |MYSQL_user="" MYSQL_password="" MYSQL_host="127.0.0.1"            |
|MYSQL_dbs_name          |databse names|('test1' 'test2')|
|Mongo Databases credentials          |mongo  username,password,host (if you need mongo database backup)|MONGO_user="" MONGO_password="" MONGO_port="27017"|
|FTP Data          |ftp  username,password,host |USERNAME="fsf" PASSWORD="fasdf" SERVER="1.1.1.1" PORT="21"|
|REMOTEDIR          |Remote directory, the backup will be placed|"./server1"|
|TYPE          |Transfer type, #0=Dont Send #1=FTP #2=SFTP|TYPE=1|
|DELE          |Delete local backups after send|DELE=0|
|LOGSTATE          |Log all event, daily log in logs directorie|LOGSTATE=0|
|Database Active          |Wich database active|MYSQL=1 MONGO=1|
|REMOTEKEEP          |Count backups Keep IN Remote|REMOTEKEEP=5|
|KEEPLB          |Keep Last backup in Local|KEEPLB=1|
