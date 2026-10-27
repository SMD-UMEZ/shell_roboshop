#!/bin/bash

AMI_ID="ami-0055977a6e828a4f4"
ZONE="Z0556960G0CHQIF223HF"
DOMAIN="mylab.sbs"

for instance in $@
do 
      echo "Launching $instance instance"
   INSTANCE_ID=$(aws ec2 run-instances \
   --image-id $AMI_ID \
   --instance-type t3.micro \
   --security-groups 'common' 'roboshop-'$instance'' \
   --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='roboshop-$instance'}]' \
   --query 'Instances[0].InstanceId' \
   --output text
                   )
      echo "instance_id= $INSTANCE_ID"

     if [ $instance == "frontend" ]; then
           IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].{InstanceId: InstanceId, PublicIp: PublicIpAddress}" \
    --output text)
     R53_ID="$DOMAIN"
    else
     IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].{InstanceId: InstanceId, PrivateIp: PrivateIpAddress}" \
    --output text)
    R53_ID="$instance.$DOMAIN"
    fi

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE \
    --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$R53_ID'","Type":"A","TTL":1,"ResourceRecords":[{"Value":"'$IP'"}]}}]}'
done