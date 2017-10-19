#!/bin/bash
# Author Micah Martin - Knif3

VERSION="1.0"
TAUTH_CONF_ROOT="/etc/tauth"
TAUTH_CONF=$TAUTH_CONF_ROOT/"tauth_config"
TAUTH_ROOT="/usr/local/tauth"

#Colors for display
NOCOLOR='\033[0m'
red() { CRED='\033[0;31m'; echo -e ${CRED}$1${NOCOLOR}; }
blue() { CBLUE='\033[0;36m'; echo -e ${CBLUE}$1${NOCOLOR}; }
green() { CGREEN='\033[0;32m'; echo -e ${CGREEN}$1${NOCOLOR}; }

load_settings() {
if [[ -f $TAUTH_CONF ]]; then
	EMAIL_User=$(cat $TAUTH_CONF | grep EmailUser | awk '{print $2}')
	EMAIL_Pass=$(cat $TAUTH_CONF | grep EmailPass | awk '{print $2}')
	EMAIL_Serv=$(cat $TAUTH_CONF | grep EmailServer | awk '{print $2}')
	ALLOW_EMAIL=$(cat $TAUTH_CONF | grep AllowEmail | awk '{print $2}')
    	ALLOW_EMAIL=${ALLOW_EMAIL,,}
	ALLOW_SMS=$(cat $TAUTH_CONF | grep AllowSMS | awk '{print $2}')
    	ALLOW_SMS=${ALLOW_SMS,,}
	PHONEINFO=$(cat $TAUTH_CONF | grep PhoneCarrier | awk '{print $2}')
	BANNER=$(cat $TAUTH_CONF | grep Banner | awk '{print $2}')
	
	# LOG=$(cat $TAUTH_CONF | grep AllowEmail | awk '{print $2}')
#	if [ $SSH_CONF == "" | $EMAIL_Only == "" ]; then
#		red "Configuration file errors!"
#		red "SshConfig missing or EmailOnly missing"
#	#green "Configuration file loaded"
#	fi
else
	red "No configuration file found! Restart Program!"
	exit
fi
}



value=$(head /dev/urandom | tr -dc 0-9 | head -c6)
code="T-$value"

sel() {
while true; do
    read -e -p "Choose SMS or EMAIL: " -i "sms" method
    if [ "$?" != "0" ]; then
	red "\nTimeout exceeded";
	exit
    fi
    case $method in
        "EMAIL" | "email" | "e") 
		send "email"
		break;;
        "sms" | "SMS" | "s" )
		if [ "$ALLOW_SMS" == "web" ]; then
		    send "sms"
		elif [ "$ALLOW_SMS" == "email" ]; then
		    send "ssms"
		else
		    red "No SMS service! Sending email..."
		    send "email"
		fi
		break;;
        * ) echo "Please choose SMS or EMAIL";;
    esac
done
}

get_info() {
#Gets the hostname from the connection
SIP=$(echo $SSH_CONNECTION | awk '{print $1}')
if [ "$(command -v nslookup)" != "" ]; then
    SHOST=$(nslookup $SIP | grep 'name =' | awk '{print $4}')
else
    SHOST="Unknown"
fi
SFIN="$SHOST [$SIP]"
}

log() {
#log a command with status of $1
#echo "$1"$'\t'"$(date +"%m-%d-%y_%H:%M:%S")"$'\t'"$(whoami)"$'\t'"$SIP"$'\t'"$SHOST" >> $LOG
:
}

#send mode[ssms|sms|email]
send() {

if [ $1 == "email" ]; then
	echo -e "Subject: TAUTH code\n\nCode: $code\nFrom: $SFIN" > /tmp/mail.txt
	curl -sS --url "$EMAIL_Serv" --ssl-reqd --mail-from "$EMAIL_User" --mail-rcpt "$EMAIL" --upload-file /tmp/mail.txt --user "$EMAIL_User:$EMAIL_Pass" --insecure
	green "Email sent to $(whoami)"
	rm /tmp/mail.txt
elif [ $1 == "sms" ]; then
	message="message=$code"
	sent=$(curl -s http://textbelt.com/text -d number=$PHONE -d $message)
	green "Code sent..."
	success=$(echo $sent | cut -d" " -f3)
	if [ $success == "true" ]; then 
		green "Success! Please wait up to 1 minute for code to arrive..."
	else
		red "Sending code failed!! Restart to try Email"
		exit
	fi
# secure sms setup with email to text
elif [ $1 == "ssms" ]; then
	echo -e "Subject: TAUTH code\n\nCode: $code\nFrom: $SFIN" > /tmp/mail.txt
	curl -sS --url "$EMAIL_Serv" --ssl-reqd --mail-from "$EMAIL_User" --mail-rcpt "$PHONE$CARRIER" --upload-file /tmp/mail.txt --user "$EMAIL_User:$EMAIL_Pass" --insecure
	green "Text sent to $(whoami)"
	rm /tmp/mail.txt
else
	red "No email to text service!"
	exit
fi

}

main_login() {
read -e -t 60 -p "Enter Code: T-" pass
if [ "$?" != "0" ]; then
    red "\nTimeout exceeded";
    exit
fi
case $pass in
    $value ) 
	green "Accepted Code!"
    log "LOGIN"
	$USER_SHELL
	blue "Thank you for using tauth"
	exit
    ;;
    * )
	red "Incorrect! Removing from server..."
    log "FAILED"
    ;;
esac
}

load_user() {
#check if the user has tauth files
#if not, directly login
USER=$(whoami)
USER_CONF="/home/$USER/.tauth/user_config"
USER_DIR="/home/$USER/.tauth"
if [[ -f $USER_CONF ]]; then
	EMAIL=$(cat $USER_CONF | grep "Email " | awk '{print $2}')
	PHONE=$(cat $USER_CONF | grep "Phone " | awk '{print $2}')
	CARRIER=$(cat $USER_CONF | grep "Carrier " | awk '{print $2}')
	USER_SHELL=$(getent passwd $USER | cut -d: -f7)
else
	# Default action for non-tauth users
	# Uncomment the following line to let them login as normal
	# $USER_SHELL
	red "Not a tauth user! Removing from server..."
	exit
fi
}

[ "$BANNER" != "" ] && blue "$BANNER";
load_settings
load_user
get_info

blue "Please login with authentication code"
#Select message version and send code
if [ "$EMAIL_Only" != "yes" ]; then
	sel
else
	send "email"
fi
#read users input
main_login

