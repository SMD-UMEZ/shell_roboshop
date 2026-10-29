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


dnf list installed nodejs &>> $LOG_FILE

if [ $? -eq 0 ]; then
 echo -e " $TIMESTAMP {INFO} $Y  nodejs is already installed....SKIPPING $N " | tee -a $LOG_FILE
 else

 dnf module disable nodejs -y &>> $LOG_FILE
 dnf module enable nodejs:20 -y &>> $LOG_FILE
 Valid $? "disabling nodejs and enabling nodejs:20"

 echo "Installing nodejs......"
dnf install nodejs -y  &>> $LOG_FILE
 Valid $? "Installing nodejs"
fi
id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
 Valid $? "creating system user with login creds"
 else
  echo -e "roboshop user is already created $Y skipping..... $N "
fi
 rm -rf /app

 mkdir -p /app
 Valid $? "Creating app directory"

 rm -rf /tmp/catalogue.zip

 curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
 cd /app 
 unzip /tmp/catalogue.zip &>> $LOG_FILE
 npm install 
 Valid $? "Unzipping code and installing dependencies"

 cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
 Valid $? "creating systemctl service"

 cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
 Valid $? "Adding Mongo repo"

 dnf install mongodb-mongosh -y &>> $LOG_FILE
 Valid $? "Installing MongoDB"

 INDEX=$(mongosh --host mongoDB.mylab.sbs --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
 if [ $INDEX -lt 0 ]; then

 mongosh --host mongoDB.mylab.sbs </app/db/master-data.js &>> $LOG_FILE
 Valid $? "Loading products into mongoDB"
 else
  echo -e "Products already loaded $Y SKIPPING.....$N "
  fi 
 systemctl daemon-reload &>> $LOG_FILE
 systemctl enable --now catalogue &>> $LOG_FILE
 Valid $? "Enabling and starting catalogue"