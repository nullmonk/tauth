#!/bin/bash
 . source_code.sh
code=$(head /dev/urandom | tr -dc 0-9 | head -c5)

sel() {
while true; do
    read -e -p "Choose SMS or EMAIL: " -i "email" method
    case $method in
        "EMAIL" | "email" | "e") 
		send "email"
		break;;
        "sms" | "SMS" | "s" )
		if [ $EMAIL_Only == "Yes" | $EMAIL_Only == "yes" ]; then
			red "No SMS service! Sending email..."
			send "email"
		else
			send "sms"
		fi
		break;;
        * ) echo "Please choose SMS or EMAIL";;
    esac
done
}

#send mode[sms|email]
send() {
if [ $1 == "email" ]; then
	echo -e "Subject: TAUTH Authentication Code\n\n$code" > mail.txt
	curl -sS --url "$EMAIL_Serv" --ssl-reqd --mail-from "$EMAIL_User" --mail-rcpt "$EMAIL" --upload-file mail.txt --user "$EMAIL_User:$EMAIL_Pass" --insecure
	green "Email sent to $EMAIL"
	rm mail.txt
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
else
	red "No email to text service!"
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
if [ "$EMAIL_Only" != "yes" ]; then
	sel
else
	send "email"
fi
#read users input
main_login

