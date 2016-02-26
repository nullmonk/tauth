#!/bin/bash
VERSION="1.0"
SSH_CONF=""
EMAIL_User=""
EMAIL_Pass=""
EMAIL_Serv="smtps://smtp.gmail.com:465"
TAUTH_CONF="/etc/tauth/tauth_config"
USERS="/etc/tauth/users"

NOCOLOR='\033[0m'
red() { CRED='\033[0;31m'; echo -e ${CRED}$1${NOCOLOR}; }
blue() { CBLUE='\033[0;34m'; echo -e ${CBLUE}$1${NOCOLOR}; }
green() { CGREEN='\033[0;32m'; echo -e ${CGREEN}$1${NOCOLOR}; }

uninstall_tauth() {
#remove line ffrom ssh conf
if [ $(tail -n 1 $SSH_CONF | grep tauth) != "" ]; then
	head -n -1 $SSH_CONF > /etc/sshtemp ; mv /etc/sshtemp $SSH_CONF
	green "Removed line from ssh configuration"
fi
#remove folders
rm -R "/etc/tauth"
green "Removed /etc/tauth"
rm -R "/usr/local/tauth"
green "Removed /usr/local/tauth"
rm "/usr/local/sbin/TAUTH"
green "Removed /usr/local/sbin/TAUTH"
#remove folder stuff
for D in `cat $USERS`;
do
	USER_CONF="$D/user_config"
	USER_DIR="$D"
	if [[ -f $USER_CONF ]]; then
		chattr -i $USER_CONF
		rm $USER_CONF
	fi
	if [[ -d $USER_DIR ]]; then
		rmdir $USER_DIR
		green "$D removed from TAUTH"
	fi
done
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

ifdir() {
if [[ -d $1 ]]; then
	rm -R $1
fi
}
iffile() {
if [[ -d $1 ]]; then
	rm $1
fi
}

show_all() {
echo -e $(ls -R "/etc/tauth")
echo -e $(ls -R "/usr/local/tauth")
echo -e $(ls -R "/usr/local/sbin/TAUTH")
echo "Line added to $SSH_CONF"
echo ".tauth folders added to active users (chattr -i to remove tauth_config)"
}
write_settings() {
if [[ ! -d /etc/tauth ]]; then
	mkdir /etc/tauth
fi
echo "Version "$VERSION > $TAUTH_CONF
echo "EmailUser "$EMAIL_User >> $TAUTH_CONF
echo "EmailPass "$EMAIL_Pass >> $TAUTH_CONF
echo "EmailServer "$EMAIL_Serv >> $TAUTH_CONF
green "Settings updated!"
}

load_settings() {
if [[ -f $TAUTH_CONF ]]; then
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

check_root() {
#check root
if [ $(whoami) != "root" ]; then
	red "restart as root!"
	red "Exiting...."
	exit
fi
}

add_user() {
blue "Adding $1 to tauth"
USER_CONF="/home/$1/.tauth/user_config"
USER_DIR="/home/$1/.tauth"
#check if user has home directory
if [[ ! -d /home/$1 ]]; then
	red "User does not exist or has no home directory!"
	exit
fi
#check is .tauth folder exists and makes one if not
if [[ ! -d $USER_DIR ]]; then
	mkdir $USER_DIR
fi
#if config file exists then delete it
if [[ -f $USER_CONF ]]; then
	#print out previous user data
	blue "User has previous tauth data:"
	prev_email=$(echo $(cat $USER_CONF | grep Email | awk '{print $2}'))
	prev_phone=$(echo $(cat $USER_CONF | grep Phone | awk '{print $2}'))
	blue "[ Email: $prev_email ] [ Phone: $prev_phone ]"
	chattr -i $USER_CONF
fi
#gets user input
read -p "Enter user's SMS number: " num
read -p "Enter user's Email: " em
echo "Phone "$num > $USER_CONF
echo "Email "$em >> $USER_CONF
echo $1 >> $USERS
chattr +i $USER_CONF
green $1" added to tauth!"
}

view_user() {
USER_CONF="/home/$1/.tauth/user_config"
USER_DIR="/home/$1/.tauth"
#check if user has home directory
if [[ ! -d /home/$1 ]]; then
	red "User does not exist or has no home directory!"
	exit
fi
#if config file exists then view it
if [[ -f $USER_CONF ]]; then
	#print out previous user data
	blue "$1's tauth data:"
	prev_email=$(echo $(cat $USER_CONF | grep Email | awk '{print $2}'))
	prev_phone=$(echo $(cat $USER_CONF | grep Phone | awk '{print $2}'))
	blue "[ Email: $prev_email ] [ Phone: $prev_phone ]"
fi
}

remove_user() {
blue "Removing $1 from tauth"
USER_CONF="/home/$1/.tauth/user_config"
USER_DIR="/home/$1/.tauth"
#check if user has home directory
#if so removes .tauth and .tauth/user_config
if [[ ! -d /home/$1 ]]; then
	red "User does not exist or has no home directory!"
	exit
fi

if [[ -f $USER_CONF ]]; then
	chattr -i $USER_CONF
	rm $USER_CONF
fi
if [[ -d $USER_DIR ]]; then
	rmdir $USER_DIR
fi
green "$1 removed from tauth"
}

email_tauth() {
if [ $1 = "view" ]; then
	blue "[ Email: $EMAIL_User ] [ Password: "${EMAIL_Pass:0:1}"******* ]"
	blue "[ Server: $EMAIL_Serv ]"
else
	read -p "Enter Gmail address: " EMAIL_User
	read -p "Enter Gmail password: " -s EMAIL_Pass
	write_settings
fi
}

init() {
check_root
load_settings
}

case $1 in
	uninstall)
        	uninstall_tauth
        	;;
	add)
        	init
		add_user $2
        	;;
	view)
		init		
		view_user $2
		;;
	email)
		init
		email_tauth
		;;
	remove)
        	remove_user $2
        	;;
	showall)
        	show_all
        	;;
	version)
        	echo "tauth v${VERSION}"
        	exit 0
        	;;
    	*)
        cat <<__EOF__
Usage: $0 <command> <arguments>
VERSION $VERSION
Available commands:
    uninstall
        Remove all TAUTH features
    add
        Enables a user with tauth. Prompts for users email and phone.
        $0 add [USER]
    view
	View the settings of a tauth user.
	$0 view [USER]
    email
	$0 email change
	    change the email settings for tauth
	$0 email view
	    view the email settings for tauth
    remove
	Removes tauth from a users account
	$0 remove [USER]
    showall
	Shows all the locations tauth affects
	$0 showall
    version
        prints the tauth version
__EOF__
        ;;
esac
