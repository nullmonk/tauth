#!/bin/bash
VERSION="1.0"
SSH_CONF=""
EMAIL_User=""
EMAIL_Pass=""
EMAIL_Serv="smtps://smtp.gmail.com:465"
GITHUB_LOCATION="https://raw.githubusercontent.com/micahjmartin/main/master/tauth"
TAUTH_CONF="/etc/tauth/tauth_config"
TAUTH_ROOT="/usr/local/tauth"

NOCOLOR='\033[0m'
red() { CRED='\033[0;31m'; echo -e ${CRED}$1${NOCOLOR}; }
blue() { CBLUE='\033[0;34m'; echo -e ${CBLUE}$1${NOCOLOR}; }
green() { CGREEN='\033[0;32m'; echo -e ${CGREEN}$1${NOCOLOR}; }

write_settings() {
if [[ ! -d /etc/tauth ]]; then
	mkdir "/etc/tauth"
fi
echo "Version "$VERSION > $TAUTH_CONF
echo "EmailUser "$EMAIL_User >> $TAUTH_CONF
echo "EmailPass "$EMAIL_Pass >> $TAUTH_CONF
echo "EmailServer "$EMAIL_Serv >> $TAUTH_CONF
echo "Users "$USERS >> $TAUTH_CONF
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
mkdir $TAUTH_ROOT
curl -sS $GITHUB_LOCATION/tauth-login.sh >> $TAUTH_ROOT/tauth-login.sh
curl -sS $GITHUB_LOCATION/tauth-manager.sh >> /usr/local/tauth/tauth-manager.sh
#make programs executable
chmod +x $TAUTH_ROOT/tauth-manager.sh
chmod +x $TAUTH_ROOT/tauth-login.sh
#make sym link to tauth manager
ln -s "$TAUTH_ROOT/tauth-manager.sh" "/usr/local/sbin/TAUTH"
#read user input and write it to config file
read -p "Enter Gmail address: " EMAIL_User
read -p "Enter Gmail password: " -s EMAIL_Pass
write_settings
#back up ssh data and append tauth line
cp $SSH_CONF "$SSH_CONF.bac"
echo "ForceCommand $TAUTH_ROOT/tauth-login.sh" >> $SSH_CONF
echo
green "Install Successfull!"
}

check_root
check_ssh
install_tauth
service ssh restart
rm $0
