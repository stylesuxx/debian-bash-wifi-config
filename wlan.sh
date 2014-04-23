#!/bin/bash
# run as sudo or make sure you are allowed to use:
# * iw
# * iwlist
# * wpa_passphrase
# * wpa_supplicant
# * dhclient 

initVars() {
	DEVICE="DEVICE_NOT_SET"
	NETWORK="NETWORK_NOT_SET"
	PASSWORD="PASSWORD_NOT_SET"

	TEMPFILE1=/tmp/wlan_dialog_1_$$
	TEMPFILE2=/tmp/wlan_dialog_2_$$
}

# Let the user select one of the available wifi devices
selectDevice() {
	iw dev | grep Interface | cut -d" " -f2 > $TEMPFILE1
	options=()
	counter=1
	while read -r line; do
	     options+=($counter "$line")
	     counter=$((counter + 1))
	done < $TEMPFILE1
	dialog  --clear --title "WiFi configuration" \
			--menu "Choose WiFi device:" 0 0 0 "${options[@]}" 2> $TEMPFILE2
	proceed

	device=`cat $TEMPFILE2`
	DEVICE=`sed -n ${device}p < $TEMPFILE1`
}

# Scan networks for the given device and let the user choose one
selectNetwork() {
	dialog  --title "Scanning" \
			--infobox "Scanning for networks..." 3 50

	ifconfig $DEVICE up > /dev/null
	dhclient -r $DEVICE > /dev/null
	rm /var/lib/dhcp/dhclient.leases
	iwlist $DEVICE scan | grep ESSID | cut -d"\"" -f2 > $TEMPFILE1
	options=()
	counter=1
	while read -r line; do
		options+=($counter "$line")
	    counter=$((counter + 1))
	done < $TEMPFILE1
	
	if [ $counter == 1 ]; then
		dialog  --title "WiFi error" \
				--yesno "Could not find any networks.\n\nRedo configuration?" 0 0
		proceed
	else
		dialog  --clear --title "WiFi selection" \
				--menu "Choose a network to connect to:" 0 0 5 "${options[@]}" 2> $TEMPFILE2
		proceed

		network=`cat $TEMPFILE2`
		NETWORK=`sed -n ${network}p < $TEMPFILE1`

		selectEncryption
	fi
}

checkIP() {
	gotIP=`ifconfig $DEVICE | grep "inet addr" | wc -l`

	if [ $gotIP == 1 ]; then
		dialog  --title "WiFi connection established" \
				--msgbox "Successfully connected to:\n\n${NETWORK}" 0 0
		clean
		exit
	else
		dialog --yesno "Could not connect to ${NETWORK}. Redo configuration?" 0 0
		proceed
	fi
}

setPassword() {
	dialog  --clear --title "WiFi password" \
			--inputbox "Set your password !!!CLEARTEXT!!!" 0 0 2> $TEMPFILE1
	PASSWORD=`cat $TEMPFILE1`
}

selectEncryption() {
	dialog  --clear --title "Encryption" \
			--menu "Select encryption" 0 0 5 \
				1 "None" \
				2 "WEP" \
				3 "WPA" 2> $TEMPFILE1
	proceed

	choice=`cat $TEMPFILE1`
	case $choice in
  		1) 
			connecting
			iwconfig ${DEVICE} essid "${NETWORK}" > /dev/null
			dhclient ${DEVICE} > /dev/null
			checkIP
			;;

  		2)	setPassword
			
			;;

  		3)	setPassword
			connecting
			wpa_passphrase ${NETWORK} ${PASSWORD} > wpa_psk_${NETWORK}.conf
			killall wpa_supplicant 2> /dev/null
			wpa_supplicant -i ${DEVICE} -c wpa_psk_${NETWORK}.conf -B 2> /dev/null
			dhclient ${DEVICE}
			checkIP
			;;
	esac
}

connecting() {
	dialog --infobox "Connecting to ${NETWORK}..." 3 50
}

proceed() {
	if [ $? != 0 ]; then
		clean
		exit
	fi
}

clean() {
	rm /tmp/wlan_dialog*
	PASSWORD=""
	clear
}

while true; do
	initVars
	selectDevice
	selectNetwork
	clean
done

clean