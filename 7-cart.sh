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

 rm -rf /tmp/cart.zip

 curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
 cd /app 
 unzip /tmp/cart.zip &>> $LOG_FILE
 npm install 
 Valid $? "Unzipping code and installing dependencies"

 cp $script_dir/cart.service /etc/systemd/system/cart.service
 Valid $? "creating systemctl service"

systemctl daemon-reload
systemctl enable cart 
systemctl start cart
echo -e "$G Enabling and restarting the services successfully.....$N"