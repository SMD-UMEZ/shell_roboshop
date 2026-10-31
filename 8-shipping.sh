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

dnf list installed maven &>> $LOG_FILE

if [ $? -eq 0 ]; then
 echo -e " $TIMESTAMP {INFO} $Y  maven is already installed....SKIPPING $N " | tee -a $LOG_FILE
 else

 dnf install maven -y &>> $LOG_FILE
 Valid $? maven installation
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

 rm -rf /tmp/shipping.zip
 curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
cd /app 
unzip /tmp/shipping.zip &>> $LOG_FILE
Valid $? "Unzipping code and installing dependencies"

cd /app 
mvn clean package &>> $LOG_FILE
mv target/shipping-1.0.jar shipping.jar &>> $LOG_FILE

cp $script_dir/shipping.service /etc/systemd/system/shipping.service
 Valid $? "creating systemctl service"

 dnf install mysql -y &>> $LOG_FILE
 Valid $? Installing mysql

 mysql -h mysql.mylab.sbs -u root -pRoboShop@1 -e "use cities"

if [ "$?" -eq 0 ]; then
    echo "Data is already loaded ($TABLE_COUNT tables found)."
else
    echo "Database is empty. Proceeding with data load..."
    mysql -h mongoDB.mylab.sbs -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h mongoDB.mylab.sbs -uroot -pRoboShop@1 < /app/db/app-user.sql
    mysql -h mongoDB.mylab.sbs -uroot -pRoboShop@1 < /app/db/master-data.sql
fi

systemctl daemon-reload
systemctl enable shipping 
systemctl start shipping
systemctl restart shipping
Valid $? "enabling , starting and restarting shipping"