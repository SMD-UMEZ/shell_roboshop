#!/bin/bash

LOGS_DIR=/var/log/roboshop
sudo mkdir -p $LOGS_DIR
chown -R ec2-user:ec2-user $LOGS_DIR
chmod -R 755 $LOGS_DIR
LOG_FILE="$LOGS_DIR/$0.log"
script_dir=$pwd

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

dnf module disable nginx -y &>> $LOG_FILE
dnf module enable nginx:1.24 -y &>> $LOG_FILE
dnf install nginx -y &>> $LOG_FILE
Valid $? "Installing Nginx"

systemctl enable nginx &>> $LOG_FILE
systemctl start nginx &>> $LOG_FILE
Valid $? "Enabling and starting"

rm -rf /usr/share/nginx/html/* 
Valid $? "Removing default html files"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
Valid $? "Downloading and extracting zip file"

cp $script_dir/nginx.con /etc/nginx/nginx.conf
 Valid $? "creating systemctl service"

 systemctl restart nginx 
 Valid $? "Restarting Nginx"
