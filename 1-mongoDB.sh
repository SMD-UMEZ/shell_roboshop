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

cp mongo.repo /etc/yum.repos.d/mongo.repo
Valid $? "Adding Mongo Repo"

Validation() {
    if [ $2 -ne 0 ]; then
    echo -e " $TIMESTAMP [ERROR] $R $1 is failed to install $N " | tee -a $LOG_FILE
    else
    echo -e " $TIMESTAMP  {INFO} $G $1 is successfully installed $N " | tee -a $LOG_FILE
    fi
}
dnf list installed mongodb-org &>> $LOG_FILE

if [ $? -eq 0 ]; then
 echo -e " $TIMESTAMP {INFO} $Y  Mongo DB is already installed....SKIPPING $N " | tee -a $LOG_FILE
 else
 echo "Installing MongoDB......"
 dnf install mongodb-org -y &>> $LOG_FILE
 Validation MongoDB $?
fi
 systemctl enable mongod
 systemctl start mongod
 