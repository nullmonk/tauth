#!/bin/bash
TAUTH_CONF="/etc/tauth/tauth_config"
TAUTH_CONF_ROOT="/etc/tauth"
TAUTH_ROOT="/usr/local/tauth"

code=$(head /dev/urandom | tr -dc 0-9 | head -c5)


NOCOLOR='\033[0m'
red() { CRED='\033[0;31m'; echo -e ${CRED}$1${NOCOLOR}; }
blue() { CBLUE='\033[0;34m'; echo -e ${CBLUE}$1${NOCOLOR}; }
green() { CGREEN='\033[0;32m'; echo -e ${CGREEN}$1${NOCOLOR}; }


uninstall() {
rm -R $TAUTH_ROOT
rm -R $TAUTH_CONF_ROOT
if [ $(tail -n 1 /etc/ssh/sshd_config | grep tauth) != "" ]; then
	head -n -1 /etc/ssh/sshd_config > /etc/ssh/sshtemp ; mv /etc/ssh/sshtemp /etc/ssh/sshd_config
fi
}
sel() {
while true; do
    read -e -p "Choose SMS or EMAIL: " -i "email" method
    case $method in
        "EMAIL" | "email" | "e") 
		
		echo -e "Subject: TAUTH Authentication Code\n\n$code" > mail.txt
		curl -sS --url "$EMAIL_Serv" --ssl-reqd --mail-from "$EMAIL_User" --mail-rcpt "$EMAIL" --upload-file mail.txt --user "$EMAIL_User:$EMAIL_Pass" --insecure
		green "Email sent to $EMAIL"
		rm mail.txt
	break;;
        "sms" | "SMS" | "s" ) 
		message="message=Authentication:$code"
		sent=$(curl -s http://textbelt.com/text -d number=$PHONE -d $message)
		green "Code sent..."
		success=$(echo $sent | cut -d" " -f3)

		if [ $success == "true" ]; then 
			green "Success! Please wait up to 1 minute for code to arrive..."
		else
			red "Sending code failed!! Restart to try Email"
			exit
		fi

		break;;
        * ) echo "Please choose SMS or EMAIL";;
    esac
done
}

load_settings() {
if [[ -f /etc/tauth/tauth_config ]]; then
	EMAIL_User=$(cat $TAUTH_CONF | grep EmailUser | awk '{print $2}')
	EMAIL_Pass=$(cat $TAUTH_CONF | grep EmailPass | awk '{print $2}')
	EMAIL_Serv=$(cat $TAUTH_CONF | grep EmailServer | awk '{print $2}')
	USERS=$(cat $TAUTH_CONF | grep Users | awk '{print $2}')
	#green "Configuration file loaded"
else
	red "No configuration file found! Restart Program!"
	exit
fi
}

main_login() {
read -e -p "Enter Code: " pass
if [ $pass == $code ]; then
	green "Accepted Code!"
	/bin/bash
	blue "Thank you for using t-auth"
	exit
else
	red "Incorrect! Removing from server..."
fi
}

load_user() {
#check if the user has tauth files
#if not, directly login
USER=$(whoami)
USER_CONF="/home/$USER/.tauth/user_config"
USER_DIR="/home/$USER/.tauth"
if [[ -f $USER_CONF ]]; then
	EMAIL=$(cat $USER_CONF | grep Email | awk '{print $2}')
	PHONE=$(cat $USER_CONF | grep Phone | awk '{print $2}')
else
	tauth_login $code
fi
}

tauth_login() {
if [ $1 == $code ]; then
	/bin/bash
	blue "Thank you for using t-auth"	
	exit
else
	red "Incorrect! Removing from server..."
fi
}

blue "Server secured with TAUTH"
load_settings
load_user

blue "Please login with authentication code"
#Select message version and send code
sel
#read users input
main_login

