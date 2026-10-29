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


dnf list installed redis &>> $LOG_FILE

if [ $? -eq 0 ]; then
 echo -e " $TIMESTAMP {INFO} $Y  redis is already installed....SKIPPING $N " | tee -a $LOG_FILE
 else
 dnf module disable redis -y &>> $LOG_FILE
 dnf module enable redis:7 -y &>> $LOG_FILE
 echo "Installing redis......"
 dnf install redis -y  &>> $LOG_FILE
 Valid $? "Installing redis"
fi

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
Valid $? "Configuring the redis

 systemctl enable --now redis
 Valid $? "Enabling and starting redis "


 