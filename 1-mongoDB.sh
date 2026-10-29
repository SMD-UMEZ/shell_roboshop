#!/bin/bash

LOGS_DIR=/var/log/roboshop
sudo mkdir -p $LOGS_DIR
chown -R ec2-user:ec2-user $LOGS_DIR
chmod -R 755 $LOGS_DIR
LOG_FILE="$LOGS_DIR/$0.log"

USER_ID=$(id -u)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[0m'

if [ $USER_ID -ne 0 ]; then
    echo -e " $TIMESTAMP $R [ERROR] please login as root user and run this script with root access $N " | tee -a $LOG_FILE
    exit 1
fi
Valid() {
    if [ $1 -ne 0 ]; then
    echo -e " $TIMESTAMP [ERROR] $R $2 is failed $N " | tee -a $LOG_FILE
    else
    echo -e " $TIMESTAMP {INFO} $G  $2 is success $N " | tee -a $LOG_FILE
    fi
}

rm -rf /etc/yum.repos.d/mongo.repo

cp mongo.repo /etc/yum.repos.d/mongo.repo
Valid $? "Adding Mongo Repo"

dnf list installed mongodb-org &>> $LOG_FILE

if [ $? -eq 0 ]; then
 echo -e " $TIMESTAMP {INFO} $Y  Mongo DB is already installed....SKIPPING $N " | tee -a $LOG_FILE
 else
 echo "Installing MongoDB......"
 dnf install mongodb-org -y &>> $LOG_FILE
 Valid $? "Installing mongodb"
fi
 systemctl enable --now mongod
 Valid $? "Enabling and starting mongodb"

 sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
 Valid $? "configuring the Host server"

 systemctl restart mongod
 Valid $? "Restarting the mongodb"

 