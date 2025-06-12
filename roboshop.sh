#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0677980401ba4a8dd"
INSTANCES=("mangodb" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z06972962YER5TY40HSFX"
DOMAIN_NAME="gana84s.site"

for instance in ${INSTANCES[@]}
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.
    micro --security-group-ids sg-0677980401ba4a8dd --tag-specifications 
    "ResourceType=instance,Tags=[{Key=Name,Value=test}]" --query "Instances[0].PrivateIpAddress" --output text)
if [ $instance !="frontend" ]
then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Instances[0].
    PrivateIpAddress" --output text)
else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Instances[0].
    PublicIpAddress" --output text)
fi
    echo "$instance IP Address: $IP"

done