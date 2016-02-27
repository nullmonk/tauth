#!/bin/bash

VERSION="1.0"
#Colors for display
NOCOLOR='\033[0m'
red() { CRED='\033[0;31m'; echo -e ${CRED}$1${NOCOLOR}; }
blue() { CBLUE='\033[0;34m'; echo -e ${CBLUE}$1${NOCOLOR}; }
green() { CGREEN='\033[0;32m'; echo -e ${CGREEN}$1${NOCOLOR}; }

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
#echo $1 >> $USERS
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
else
	red "User is not registered with TAUTH!"
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
nm=$(basename $0)
case $1 in
	add)
        	check_root
		add_user $2
        	;;
	view)
		check_root		
		view_user $2
		;;
	remove)
		check_root
        	remove_user $2
        	;;
	version)
        	echo "TAUTH v${VERSION}"
        	exit 0
        	;;
    	*)
        cat <<__EOF__
Usage: $nm <command> <arguments>
VERSION $VERSION
Available commands:
    add
        Enables a user with tauth. Prompts for users email and phone.
        $nm add [USER]
    view
	View the settings of a tauth user.
	$nm view [USER]
    remove
	Removes tauth from a users account
	$nm remove [USER]
    version
        prints the tauth version
__EOF__
        ;;
esac