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