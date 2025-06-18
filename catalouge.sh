#!/bin/bash

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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJs 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? " Install Node Js 20"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? " Creating roboshop user"

mkdir /app 
VALIDATE $? "Crating App Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Catalouge"

cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unziping catalouge"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependicies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalouge services"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reloading"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling Catalouge" 

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Starting Catalouge"

mongosh --host mongodb.gana84s.site