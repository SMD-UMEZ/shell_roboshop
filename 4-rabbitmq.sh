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


dnf list installed rabbitmq-server &>> $LOG_FILE

if [ $? -eq 0 ]; then
 echo -e " $TIMESTAMP {INFO} $Y  rabbitmq-server is already installed....SKIPPING $N " | tee -a $LOG_FILE
 else

 cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
 Valid $? "Adding rabbitMQ"

 echo "Installing rabbitmq-server......"
dnf install rabbitmq-server -y  &>> $LOG_FILE
 Valid $? "Installing rabbitmq-server"
fi
 systemctl enable --now rabbitmq-server
 Valid $? "Enabling and starting rabbitmq-server "

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
 Valid $? "root password set-up"