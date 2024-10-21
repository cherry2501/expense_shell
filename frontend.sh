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

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "install NGINX"

systemctl enable nginx -y &>>$LOG_FILE
VALIDATE $? "enable nginx"

systemctl enable nginx -y &>>$LOG_FILE
VALIDATE $? "enable nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloding frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extract frontend code"

cp /home/ec2-user/expense_shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense conf"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarted Nginx"