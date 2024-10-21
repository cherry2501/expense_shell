#!/bin/bash

LOG_FOLDER="/var/log/shell-script"
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

dnf install mysql-server -y &>>LOG_FILE
VALIDATE $? "Installing MYSQL server"

systemctl enable mysqld &>>LOG_FILE
VALIDATE $? "Enable mysql"

systemctl restart mysqld &>>LOG_FILE
VALIDATE $? "Restart mysql"

mysql -h mysql.charanworld.online -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE

if [ $? -ne 0]
then
    echo "Mysql password not set... setting password now.."
    mysql_secure_installation --set-root ExpenseApp@1
    VALIDATE $? "Root password setup"
else
    echo "Mysql password already set.."
fi
