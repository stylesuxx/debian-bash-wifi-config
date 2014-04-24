# Bash WiFi connector
Connect to a WiFi network via bash and dialog.

## Prerequisits
This should work on all Linux system where the following commands are available:
 * dialog
 * iw
 * iwlist
 * iwconfig
 * wpa_passphrase
 * wpa_supplicant
 * dhclient

#### Debian and debian flavoured:
    sudo apt-get install wireless-tools iw dialog wpasupplicant dhcp-client

## Usage
Run the script as root or make sure that the running user has the appropriate rights to execute the above commands.

    sudo ./wlan.sh