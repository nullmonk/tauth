#!/bin/bash

VERSION="0.1.1"


SSH_CONF=""

# Location paths
TAUTH_CONF_ROOT="/etc/tauth"
TAUTH_CONF=$TAUTH_CONF_ROOT/"tauth_config"
TAUTH_ROOT="/usr/local/tauth"
GITHUB_LOCATION="https://raw.githubusercontent.com/micahjmartin/tauth/master"

#Settings to read from the CONF
EMAIL_User=""
EMAIL_Pass=""
EMAIL_Serv="smtps://smtp.gmail.com:465"
AllowEmail="yes"
AllowSMS="email"
PhoneCarrier="$TAUTH_ROOT/Phoneinfo"
logs="$TAUTH_CONF_ROOT/tauth.log"

#Create color functions
NOCOLOR='\033[0m'
red() { CRED='\033[0;31m'; echo -e ${CRED}$1${NOCOLOR}; }
blue() { CBLUE='\033[0;34m'; echo -e ${CBLUE}$1${NOCOLOR}; }
green() { CGREEN='\033[0;32m'; echo -e ${CGREEN}$1${NOCOLOR}; }
#If directory exists, create it, else delete it and then create it
ifdir() {
if [[ ! -d $1 ]]; then
	mkdir -p $1
else
	rm -fr $1
	mkdir -p $1
fi
}
#Save the settings to TAUTH_CONF
write_settings() {
ifdir $TAUTH_CONF_ROOT

echo "#Settings for sending the secure email (TODO figure out a way to not store plaintext creds!!)" >> $TAUTH_CONF
echo "EmailUser "$EMAIL_User >> $TAUTH_CONF
echo "EmailPass "$EMAIL_Pass >> $TAUTH_CONF
echo "EmailServer "$EMAIL_Serv >> $TAUTH_CONF
echo "#Whether or not to allow email. Set to yes or no"  >> $TAUTH_CONF
echo "AllowEmail "$AllowEmail >> $TAUTH_CONF
echo "#Whether or not to allow sms. Set to 'no' 'web' or 'email'. Web is insecure if the network that the server is on can be sniffed, However, this does not require Phone Carriers"  >> $TAUTH_CONF
echo "AllowSMS $AllowSMS"  >> $TAUTH_CONF
echo "#location of the phone carrier information file" >> $TAUTH_CONF
echo "PhoneCarrier $PhoneCarrier"  >> $TAUTH_CONF
#echo "#Location of the log file" >> $TAUTH_CONF
#echo "Log $logs" >> $TAUTH_CONF
green "Settings written to $TAUTH_CONF!"
}

check_root() {
#check root
if [ $(whoami) != "root" ]; then
	red "restart as root!"
	red "Exiting...."
	exit
fi

# Check dependencies
missing=""
command -v curl;
[ "$?" != "0" ] && missing="$missing\n\tcurl"
command -v sshd;
[ "$?" != "0" ] && missing="$missing\n\tsshd"

if [ "$missing" != "" ]; then
    red "Install the following dependencies:$missing";
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
		exit
	fi
fi
}

install_tauth() {
#make directory and curl program
ifdir $TAUTH_ROOT
curl -sS $GITHUB_LOCATION/tauth-login.sh >> $TAUTH_ROOT/tauth-login.sh
curl -sS $GITHUB_LOCATION/tauth-manager.sh >> $TAUTH_ROOT/tauth-manager.sh
curl -sS $GITHUB_LOCATION/Phoneinfo >> $TAUTH_ROOT/Phoneinfo
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
#read user input and write it to config file
read -p "Enter Gmail address: " EMAIL_User
read -p "Enter Gmail password: " -s EMAIL_Pass
#back up ssh data and append tauth line
cp $SSH_CONF "$SSH_CONF.bac"
echo "ForceCommand $TAUTH_ROOT/tauth-login.sh" >> $SSH_CONF
#create default log file
#echo "STATUS"$'\t'"TIME"$'\t'"USER"$'\t'"IP"$'\t'"HOSTNAME" >> $logs
#chmod 666 $logs
#chattr +a $logs
write_settings
green "Install Successfull!"
green "Please restart SSH server"
}

check_root
check_ssh
install_tauth
rm $0
