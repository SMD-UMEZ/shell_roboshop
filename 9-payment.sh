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

dnf install python3 gcc python3-devel -y &>> $LOG_FILE
Valid $? "Installation python3"

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

 rm -rf /tmp/payment.zip
 curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
cd /app 
unzip /tmp/payment.zip &>> $LOG_FILE
pip3 install -r requirements.txt &>> $LOG_FILE
Valid $? "Unzipping code and installing dependencies"

cp $script_dir/payment.service /etc/systemd/system/payment.service
 Valid $? "creating systemctl service"

 systemctl daemon-reload
 systemctl enable payment 
systemctl start payment
Valid $? "Enabling and starting payment"



