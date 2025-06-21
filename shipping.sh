#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

echo "Please enter your password"
read -s $MYSQL_ROOT_PASSWORD

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install maven -y $>>$LOG_FILE
VALIDATE $? "Installing Maven"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating roboshop user"
else
    echo -e "roboshop user already created $Y SKIPPING $N"

fi

mkdir -p /app $>>$LOG_FILE
VALIDATE $? "Creating App Directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Downloading Shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip $>>$LOG_FILE
VALIDATE $? "Unzipping shipping"

mvn clean package 
VALIDATE $? "packing the shoipping Aplication"

mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "mooving and remnaming the content"

systemctl daemon-reload $>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable shipping $>>$LOG_FILE
VALIDATE $? "enavling Shipping"
systemctl start shipping $>>$LOG_FILE
VALIDATE $? "stating shipping"

dnf install mysql -y $>>$LOG_FILE
VALIDATE $? "Installing mysql"

mysql -h mysql.gana84s.site -u root $MYSQL_ROOT_PASSWORD -e 'use cties'

if [ $? -ne 0 ]
then
    mysql -h mysql.gana84s.site -uroot $MYSQL_ROOT_PASSWORD < /app/db/schema.sql
    mysql -h mysql.gana84s.site -uroot $MYSQL_ROOT_PASSWORD < /app/db/app-user.sql 
    mysql -h mysql.gana84s.site -uroot $MYSQL_ROOT_PASSWORD < /app/db/master-data.sql
else
    echo -e "data already loaded... $Y SKIPPING $N"

systemctl restart shipping $>>$LOG_FILE
VALIDATE $? "Restarting the shipping"

END_TIME=$(date +%s)

TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script exection completed successfully... $Y Time taken in : $TOTAL_TIME seconds $N" | tee -a $LOG_FILE