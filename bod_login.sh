#!/bin/bash
# Auth: Ryan Thomas

new_pw=/*SCRUBBED*/
old_pw=/*SCRUBBED*/
pw=$new_pw

login() {
	if [[ $pw == $old_pw ]]; then
		echo "Logging in to $IP using the old REDACTED pw..."
	else
		echo "Logging in to $IP..."
	fi

	ssh="sshpass -p $pw ssh -t -o LogLevel=quiet -o StrictHostkeyChecking=no @$IP"
	if [[ $1 == test ]]; then
		$ssh exit
	else
		$ssh
		if [[ $? -ne 0 ]]; then
			if [[ $pw == $old_pw ]]; then
				echo "Failed to log in using old REDACTED pw, check connections."
			else
				echo "Failed to log in using current REDACTED pw, try $0 -o to attempt login using the old REDACTED pw. Alternatively, try $0 -f to clear the known_hosts file and re-attempt login."
			fi
			return 1
		fi
	fi
}

clear () {
	echo "Deleting known_hosts file..."
	[[ -f /root/.ssh/known_hosts ]] && rm /root/.ssh/known_hosts || exit 0
}

setIP200 () {
	echo "Issuing set network-parameters commands"

	SSH="sshpass -p $pw ssh -o LogLevel=quiet -o StrictHostkeyChecking=no REDACTED@$IP"
	
	$SSH<<-EOSSH
		set network-parameters ip REDACTED netmask REDACTED gateway REDACTED controller b
		exit
	EOSSH
	echo "Sleeping 2min to wait for controller to update"
	sleep 120

	$SSH<<-EOSSH
		set network-parameters ip REDACTED netmask REDACTED gateway REDACTED controller a
		exit
	EOSSH

	#set server's ip so we don't lose track of the BOD
	echo "Setting server IP to REDACTED to follow BOD. It may take a few moments to be able to detect the controller now that its address has been changed."
	ifconfig eth1 REDACTED/24 up
}

setIP () {
	if [ "$#" -ne 1 ]; then
		echo "Incorrect usage. setIP requires exactly one argument"
		exit 1
	fi
	if [[ "$1" != "REDACTED" && "$1" != "REDACTED" && "$1" != "REDACTED" ]]; then
		echo "Incorrect usage. Please assign as an argument an eligible BOD controller A IP address."
		exit 1
	fi
	
	# First 3 characters of IP address
	network_id=$(echo $1 | awk -F "." '{print $1}')

	# first 3 sets of 3 characters of IP address
	ip_nohost=$(echo $1 | awk -F "." '{print $1"."$2"."$3}') host_id=$(echo $1 | awk -F "." '{print $4}')

	# last 3 characters of IP address
	host_id_b=$((host_id+1))

	echo "Issuing set network-parameters commands"

	SSH="sshpass -p $pw ssh -tT -o LogLevel=quiet -o StrictHostkeyChecking=no @$IP"
	$SSH<<-EOSSH
		set network-parameters ip $ip_nohost.$host_id_b netmask REDACTED gateway $network_id.0.0.1 controller b
		exit
	EOSSH
	echo "Sleeping 2min to wait for controller to update"
	sleep 120

	$SSH<<-EOSSH
		set network-parameters ip $ip_nohost.$host_id netmask REDACTED gateway $network_id.0.0.1 controller a
		exit
	EOSSH

	#set server's ip so we don't lose track of the BOD
	echo "BOD Controller A set to $ip_nohost.$host_id"
	echo "Setting server to $ip_nohost.10"
	ifconfig eth1 $ip_nohost.10
	echo "Sleeping 30s to let Controller A reset."
	sleep 30
}

test () {
	# login then immediately exit--intended for testing which password works
	pw=$new_pw
	login test
	if [[ $? -gt 0 ]]; then
		# new pw failed, test old pw
		pw=$old_pw
		login test
		if [[ $? -gt 0 ]]; then
			# bod was unable to be logged into with either pass, return 3
			exit 3
		fi
		# bod has old pass set, return 2
		exit 2
	fi
	#bod has new pass set, exit with no error
	exit 0
}

updatePassword () {
	SSH="sshpass -p $old_pw ssh -o LogLevel=quiet -o StrictHostkeyChecking=no REDACTED@$IP"
	$SSH<<-EOSSH
		****BLOCK REDACTED****
	EOSSH
}

usage () {
cat<<EOF
This bod tool is designed to automate some processes performed during the RMA process for 5U84(BOD) units. 

Script does not support multiple-option inputs. 
Usage: $0 [option]
	-c | --clear
		Deletes the known_hosts file. Confirm that your ethernet cable is plugged into the correct machine before using this.
	-h | --help
		Show this usage text.
	-i {REDACTED|REDACTED|REDACTED}
		Sets the bod's controllers a/b to the desired ip pair. Default is 200.0.0.(20/21).
	-l | --login
		Login to the bod and interact with the terminal manually
	-o | --oldLogin
		Login using the old REDACTED password.
	-t | --test
		Attempts to log in using first the new, then the old password, and terminates after establishing/failing to establish a connection. Used by other scripts for its return values.
	-u | --updatePassword
		Updates the password from the old REDACTED password to the new one. Also updates the user roles and priveliges on the controller.
EOF

}

findBodIp () {
	ifconfig eth1 REDACTED/24 up
	ping -c 1 REDACTED &> /dev/null && IP=REDACTED && return
		
	ifconfig eth1 REDACTED/24 up
	ping -c 1 REDACTED &> /dev/null && IP=REDACTED && return

	ifconfig eth1 REDACTED/24 up
	ping -c 1 REDACTED &> /dev/null && IP=REDACTED && return
}

echo "Searching for BOD..."
findBodIp
if [ -z $IP ]; then
	echo "did not find BOD"
	exit 1
fi
if [ $# -eq 0 ]; then
	login
	exit 0
fi

while [ "$1" != "" ]; do
	case $1 in
	-c | --clear)
		clear
		exit 0
		;;
	-h | --help)
		usage
		exit 0
		;;
	-i | --setip200)
		if [ "$#" -gt 1 ]; then
			setIP "$2"
		else
			setIP200
		fi
		exit 0
		;;
	-l | --login)
		login
		if [[ $? -ne 0 ]]; then
			exit 1
		else
			exit 0
		fi
		;;
	-o | --oldLogin)
		pw=$old_pw
		login
		exit 0
		;;
	-t | --test)
		test
		if [[ $? -eq 3 ]]; then
			# neither password worked
			exit 1
		elif [[ $? -eq 2 ]]; then
			# bod has old pw
			exit 2
		else
			# bod has latest pw
			exit 0
		fi
		# should exit before reaching this point
		exit 4
		;;
	-u | --updatePassword)
		updatePassword
		exit 0
		;;
	*)
		usage
		exit 1
		;;
	esac
done
exit 0


