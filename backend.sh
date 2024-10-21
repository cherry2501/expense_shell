#!/bin/bash

LOG_FOLDER="/var/log/expense"
TIME_STAMP=$(date +%Y-%m-%d-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log"

mkdir -p $LOG_FOLDER 

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

USER_ID=$(id -u) #checks root user
if [ $USER_ID -ne 0 ]
then
    echo "Better use root user for installation tasks..."
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e "$2 is... $R FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is.... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install Nodejs"

id expense &>>$LOG_FILE

if [ $? -ne 0 ]
then
    echo "No existing Expense user"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "Expense user creation"
else
    echo "User already exists...:)"
fi 

mkdir -p /app
VALIDATE $? "folder /app creation"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend.zip"


npm install &>>$LOG_FILE
cp /home/ec2-user/expense_shell/backend.service /etc/systemd/system/backend.service
VALIDATE $? "copy backend file"

#loading data before running service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing mysql"

mysql -h mysql.charanworld.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reload-Daemon"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enable Backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restart Backend"

