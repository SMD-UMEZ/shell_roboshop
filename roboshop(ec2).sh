#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
ZONE="Z0556960G0CHQIF223HF"
DOMAIN="mylab.sbs"
R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[0m'

### VALIDATION  ###
 if [ $# -lt 2 ]; then
    echo -e "$R [ERROR] : At  least 2 arguments required. $N"
    echo "Usage Of $0 is [create/destroy] [Instance1 Instance2 ....]"
    exit 1
 fi

 ACTION=$1
 shift #  first arg will be removed #

 if [ $ACTION != "create" ] && [ $ACTION != "delete" ]; then
   echo -e "$R [ERROR] : First arg should be create either delete $N"
    echo "Usage Of $0 is [create/destroy] [Instance1 Instance2 ....]"
    exit 1
 fi

get_instance_id() {

    name=$1
    aws ec2 describe-instances --filters "Name=tag:Name,Values=roboshop-$name" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text
}   

 for instance in $@
 do
       INSTANCE_ID=$(get_instance_id roboshop-$instance)
       if [ $ACTION == "create" ]; then
        if [ $INSTANCE_ID == "None" ]; then
         echo "Launching the Instance : roboshop-$instance"
          INSTANCE_ID=$(aws ec2 run-instances \
   --image-id $AMI_ID \
   --instance-type t3.micro \
   --security-groups "common" "roboshop-$instance" \
   --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='roboshop-$instance'}]' \
   --query 'Instances[0].InstanceId' \
   --output text
                   )
      echo "Launched Instance : $INSTANCE_ID"
      else
       echo "roboshop-$instance is already exists : $INSTANCE_ID"
       fi
       fi


 done