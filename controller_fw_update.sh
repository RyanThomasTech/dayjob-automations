#!/bin/bash
# Auth: Ryan Thomas
# This script checks the password of the connected controller and attempts to apply a firmware update if the controller has the old REDACTED PW using the Production VPD and FW scripts. The script will then set the controllers' addresses to their 10... IP addresses for shipping. If the controllers are detected to have the current REDACTED password, the script will exit without taking action. If the -f flag is passed, the script will attempt an update regardless of which password is present on the device.

current_vpd_script=/*SCRUBBED*/
current_fw_script=/*SCRUBBED*/
bod_login=/*SCRUBBED*/

usage() {
	printf "\nScript detects bod connected via ethernet, sets its ip to 200.0.0.(20/21), attempts to update firmware, and sets controller ip to 10.0.0.(2/3) after completion.\n"
	printf "\nusage: $0 [-option]\n"
	printf "%4s -f | --force\n%8s Attempt FW update regardless of which password is on the controller.\n"
	printf "%4s -h | --help\n%8s Display this usage text\n"
}

runUpdate() {
	# Set the bod's IP to REDACTED
	$bod_login -i REDACTED

	*****REDACTED LINE*****
	$current_fw_script
	if [[ $? -eq 0 ]]; then
		*****REDACTED LINE*****
		# Set the bod's IP back to REDACTED to ship it
		$bod_login -i REDACTED
	fi
}

force=0
while [ "$1" != "" ]; do
	case $1 in
	-h | --help)
		usage
		exit 0
		;;
	-f | --force)
		# set internal force flag to true
		force=1
		break
		;;
	*)
		usage
		exit 1
		;;
	esac
done

# bod login program will return an exit code based on the state it finds
$bod_login -t
case $? in
	"0")
		# bod has latest PW, don't run FW update unless force action called
		if [[ $force -eq 1 ]]; then
			echo "BOD has latest PW, but script was called with force option. Attempting to apply firmware update."
			runUpdate
		else
			echo "BOD has the latest PW. Firmware update assumed unnecessary."
		fi
		;;
	"1")
		# Failed to access BOD
		echo "Failed to access/discover BOD using either password. Check connections"
		;;
	"2")
		# Bod has old password

		echo "BOD has old password; attempting to apply firmware update."

		# First, update the password
		$bod_login -u

		# Then run the update
		runUpdate
		;;
	"4")
		echo "Unexpected state reached. Fell out of bod_login -t case"
		;;
esac
