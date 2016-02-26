# TAUTH

TAUTH is a SMS based Two-Factor authentication program for SSH servers. TAUTH sends a SMS message or Email with a 5 digit pin that a user must enter in order to can access to a server. Users must be added individually and any user not added to TAUTH will be allowed to login as normal

## How it works

TAUTH creates a login environment that SSH forces users to use. Users cannot escape the environment without killing the connection. TAUTH allows for either SMS or email verification. In order to use the *Email features of TAUTH, You need to enter credentials of an active GMAIL account. TAUTH curls the smtp protocol of gmail and sends an email to the users email. For the SMS verification, TAUTH uses http://textbelt.com/.

*Email features may  error if no GMAIL is added

## Installation

	$ curl https://raw.githubusercontent.com/micahjmartin/main/master/tauth/tauth-install.sh > tauth-install;
	$ chmod +x tauth-install;
	$ ./tauth-install;
    $ service ssh restart

After installation restart your SSH server

## Usage

After installing TAUTH, all management is handled with

	$ TAUTH [command]

To enable TAUTH for a user

	$ TAUTH add [user]

To remove TAUTH from a specific user

	$ TAUTH remove [user]

Note: You can manually remove a user from TAUTH by removing "/home/user/.tauth",However "/home/user/.tauth/user_config" is marked as immutable