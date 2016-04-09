#!/bin/bash

VERSION="1.3"
#Colors for display
NOCOLOR='\033[0m'
TAUTHROOT="/usr/local/tauth"
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
PhoneInfo="$TAUTHROOT/Phoneinfo"

search_carrier(){
if [[ ! -f $PhoneInfo ]]; then
red "No carrier database found!"
exit
fi
if [ -z $1 ]; then
	read -p "Enter phone carrier: " pc
	searchA=${pc,,}
else
	searchA=$1
	searchA=${searchA,,}
fi
resultA=( $(cat $PhoneInfo | cut -d':' -f1 | grep "$searchA") )
count=$(echo ${#resultA[@]})
blue "Searching for [$searchA]..."
if [ $count -lt 1 ]; then
	red "No results found for [$searchA]"
	exit
elif [ $count -eq 1 ]; then
	green "Match found"
	PhoneCarrier=$(cat $PhoneInfo | grep "$searchA:" | cut -d':' -f2)
	green "Carrier set to [$resultA]"
else
	red "More then one carrier found!"
	for i in $(seq 0 $count); do
		if [ $i -eq $count ]; then
			red "$count. EXIT"
		else
			red "$i. [${resultA[i]}]"
		fi
	done
	
	re="^[0-9]+$"
	while true; do
		read -p "Please choose a number: " choice
		if [ $choice -eq $count ]; then
			exit
		elif [[ $choice =~ $re ]]; then
			PhoneCarrier=$(cat $PhoneInfo | grep "${resultA[$choice]}:" | cut -d':' -f2 )
			green "Carrier set to [${resultA[$choice]}]"
			break
		fi
	done
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
if [[ -f $PhoneInfo ]]; then
	search_carrier
	echo "Carrier "$PhoneCarrier > $USER_CONF
fi
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
USER_CONF="/home/$1/.tauth/user_config"
USER_DIR="/home/$1/.tauth"
#check if user has home directory
#if so removes .tauth and .tauth/user_config
if [[ ! -d /home/$1 ]]; then
	red "$1 does not exist or has no home directory!"
fi

if [[ -f $USER_CONF ]]; then
	chattr -i $USER_CONF
	rm $USER_CONF
fi
if [[ -d $USER_DIR ]]; then
	rmdir $USER_DIR
	green "$1 removed from tauth"
fi
}

uninstall(){
users_a=( $(ls -1 /home) )
for i in ${users_a[@]}; do
	if [[ -d "/home/$i/.tauth" ]]; then
		remove_user $i
	fi
done
if [[ -d "/etc/tauth" ]]; then
	rm -rf "/etc/tauth"
	green "Removed /etc/tauth"
fi
if [[ -d "/usr/local/tauth" ]]; then
	rm -rf "/usr/local/tauth"
	green "Removed /usr/local/tauth"
fi

cat /etc/ssh/sshd_config.bac > /etc/ssh/sshd_config

if [[ -f "/usr/local/sbin/tauth" ]]; then
rm "/usr/local/sbin/tauth"
fi
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
	uninstall)
		while true; do
    			read -p "Do you wish to uninstall? [Y/n] " yn
    				case $yn in
        			[Yy]* ) break;;
        			* ) exit;;
    			esac
		done
		check_root
		uninstall
		exit 0
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
    uninstall
	Uninstalls tauth from the computer and all users
    version
        prints the tauth version
__EOF__
        ;;
esac
