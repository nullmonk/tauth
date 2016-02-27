#!/bin/bash

#Source code for TAUTH project
#Used by:
#	tauth-login.sh
#	tauth-manager.sh


VERSION="1.0"
SSH_CONF=""
EMAIL_User=""
EMAIL_Pass=""
EMAIL_Serv="smtps://smtp.gmail.com:465"
TAUTH_CONF="tauth_config"
USERS="users"
EMAIL_Only="No"
TAUTH_CONF="tauth_config"
TAUTH_CONF_ROOT="."
TAUTH_ROOT="."


#Colors for display
NOCOLOR='\033[0m'
red() { CRED='\033[0;31m'; echo -e ${CRED}$1${NOCOLOR}; }
blue() { CBLUE='\033[0;34m'; echo -e ${CBLUE}$1${NOCOLOR}; }
green() { CGREEN='\033[0;32m'; echo -e ${CGREEN}$1${NOCOLOR}; }


check_ssh() {
#find SSH config file
if [[ -f /etc/ssh/sshd_config ]]; then
	SSH_CONF="/etc/ssh/sshd_config"
	#green "SSH config file found at "$SSH_CONF
	
else
	red "No SSH config found in /etc/ssh/sshd_config"
	read -p "Enter location of SSH config file: " loc
	if [[ -f $loc ]]; then
		SSH_CONF=$loc
		green "SSH config file found at "$SSH_CONF
	else
		red "No SSH config found in "$loc
		red "Exiting...."
	fi
fi
}


check_root() {
#check root
if [ $(whoami) != "root" ]; then
	red "restart as root!"
	red "Exiting...."
	exit
fi
}

load_settings() {
if [[ -f $TAUTH_CONF ]]; then
	EMAIL_User=$(cat $TAUTH_CONF | grep EmailUser | awk '{print $2}')
	EMAIL_Pass=$(cat $TAUTH_CONF | grep EmailPass | awk '{print $2}')
	EMAIL_Serv=$(cat $TAUTH_CONF | grep EmailServer | awk '{print $2}')
	EMAIL_Only=$(cat $TAUTH_CONF | grep EmailOnly | awk '{print $2}')
	#green "Configuration file loaded"
else
	red "No configuration file found! Restart Program!"
	exit
fi
}

write_settings() {
if [[ ! -d /etc/tauth ]]; then
	mkdir /etc/tauth
fi
echo "Version "$VERSION > $TAUTH_CONF
echo "EmailUser "$EMAIL_User >> $TAUTH_CONF
echo "EmailPass "$EMAIL_Pass >> $TAUTH_CONF
echo "EmailServer "$EMAIL_Serv >> $TAUTH_CONF
echo "EmailOnly "$EMAIL_Only >> $TAUTH_CONF
green "Settings updated!"
}


init() {
check_root
load_settings
}
