#!/bin/bash
 . source_code.sh

uninstall() {
rm -R $TAUTH_ROOT
rm -R $TAUTH_CONF_ROOT
rm "/usr/local/sbin/TAUTH"
green "Removed /usr/local/sbin/TAUTH"
if [ $(tail -n 1 /etc/ssh/sshd_config | grep tauth) != "" ]; then
	head -n -1 /etc/ssh/sshd_config > /etc/ssh/sshtemp ; mv /etc/ssh/sshtemp /etc/ssh/sshd_config
fi
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

email_tauth() {
if [ $1 = "view" ]; then
	init
	blue "[ Email: $EMAIL_User ] [ Password: "${EMAIL_Pass:0:1}"******* ]"
	blue "[ Server: $EMAIL_Serv ]"
else
	read -p "Enter Gmail address: " EMAIL_User
	read -p "Enter Gmail password: " -s EMAIL_Pass
	write_settings
fi
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
		email_tauth $2
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
