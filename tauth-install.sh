#!/bin/bash

VERSION="0.1.0"
SSH_CONF=""
#EMAIL_User=""
#EMAIL_Pass=""
EMAIL_Serv="smtps://smtp.gmail.com:465"
EMAIL_Only="No"
TAUTH_CONF_ROOT="/etc/tauth"
TAUTH_CONF=$TAUTH_CONF_ROOT/"tauth_config"
TAUTH_ROOT="/usr/local/tauth"
GITHUB_LOCATION="https://raw.githubusercontent.com/micahjmartin/tauth/master"


NOCOLOR='\033[0m'
red() { CRED='\033[0;31m'; echo -e ${CRED}$1${NOCOLOR}; }
blue() { CBLUE='\033[0;34m'; echo -e ${CBLUE}$1${NOCOLOR}; }
green() { CGREEN='\033[0;32m'; echo -e ${CGREEN}$1${NOCOLOR}; }

ifdir() {
if [[ ! -d $1 ]]; then
	mkdir -p $1
else
	rm -fr $1
	mkdir -p $1
fi
}

write_settings() {
ifdir $TAUTH_CONF_ROOT

echo "Version "$VERSION > $TAUTH_CONF
echo "#Credentials for gmail account" >> $TAUTH_CONF
echo "EmailUser "$EMAIL_User >> $TAUTH_CONF
echo "EmailPass "$EMAIL_Pass >> $TAUTH_CONF
echo "EmailServer "$EMAIL_Serv >> $TAUTH_CONF
echo "#Set to yes to force email and remove SMS"  >> $TAUTH_CONF
echo "EmailOnly "$EMAIL_Only >> $TAUTH_CONF
echo "#Set SmsMethod to 'web' for textbelt message or 'email' for email to text"  >> $TAUTH_CONF
echo "SmsMethod web"  >> $TAUTH_CONF
echo "SshConfig "$SSH_CONF >> $TAUTH_CONF
green "Settings written to $TAUTH_CONF!"
}

check_root() {
#check root
if [ $(whoami) != "root" ]; then
	red "restart as root!"
	red "Exiting...."
	exit
fi
}

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

install_tauth() {
#make directory and curl program
ifdir $TAUTH_ROOT
curl -sS $GITHUB_LOCATION/tauth-login.sh >> $TAUTH_ROOT/tauth-login.sh
curl -sS $GITHUB_LOCATION/tauth-manager.sh >> $TAUTH_ROOT/tauth-manager.sh
echo "step 1"
#make programs executable
chmod +x $TAUTH_ROOT/tauth-manager.sh
chmod +x $TAUTH_ROOT/tauth-login.sh
#make sym link to tauth manager
if [[ ! -f /usr/local/sbin/tauth ]]; then
	ln -s "$TAUTH_ROOT/tauth-manager.sh" "/usr/local/sbin/tauth"
else
	rm /usr/local/sbin/tauth
	ln -s "$TAUTH_ROOT/tauth-manager.sh" "/usr/local/sbin/tauth"
fi
echo "step 2"
#read user input and write it to config file
read -p "Enter Gmail address: " EMAIL_User
read -p "Enter Gmail password: " -s EMAIL_Pass
write_settings
echo "step 3"
#back up ssh data and append tauth line
cp $SSH_CONF "$SSH_CONF.bac"
echo "ForceCommand $TAUTH_ROOT/tauth-login.sh" >> $SSH_CONF
#create default log file
ifdir /var/log/tauth
logs="/var/log/tauth/tauth.log"
echo "STATUS"$'\t'"TIME"$'\t'"USER"$'\t'"IP"$'\t'"HOSTNAME" >> $logs
green "Install Successfull!"
green "Please restart SSH server"
}

check_root
check_ssh
install_tauth
rm $0
