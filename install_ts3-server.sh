#!/bin/bash
# Name: install_ts3-server.sh
# Version: 1.0
# Created On: 3/5/2015
# Created By: rcguy
# Description: Installs the Linux TeamSpeak 3 Server - x64
# Tested on: Ubuntu Server 14.10 x64 / VPS / 1 Cores / 512MB RAM / 20 GB SSD

# user to run the ts3server and where to install it
TS3_USER="teamspeak3"
TS3_DIR="/opt/ts3-server"

# are we root?
if	[ "$EUID" -ne 0 ]
	then
	echo -e "\nERROR!!! SCRIPT MUST RUN WITH ROOT PRIVILAGES\n"
	exit 1
fi

# exit with a non-zero status when there is an uncaught error
set -e

# add the user to run ts3server
if adduser --system --group --disabled-login --disabled-password --home $TS3_DIR $TS3_USER >/dev/null 2>&1; then
	echo -e "\nAdded new user: '$TS3_USER'"
else
	echo -e "\n ERROR!!! Failed to add new user: '$TS3_USER'\n"
	exit 1
fi

# install teamspeak3-server_linux
echo "Installing the TeamSpeak 3 server to '$TS3_DIR'"
if wget -q http://dl.4players.de/ts/releases/3.0.11.2/teamspeak3-server_linux-amd64-3.0.11.2.tar.gz; then
	tar -xzf teamspeak3-server_linux-amd64*.tar.gz
	mv teamspeak3-server_linux-amd64/* $TS3_DIR
	chown $TS3_USER:$TS3_USER $TS3_DIR -R
	rm -rf teamspeak3-server_linux-amd64*.tar.gz teamspeak3-server_linux-amd64/
else
	echo -e "\n ERROR!!! Failed to download teamspeak3-server_linux-amd64\n"
	exit 1
fi

# install the init.d startup script
touch /etc/init.d/ts3server
cat > /etc/init.d/ts3server <<EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides: ts3server
# Required-Start: \$network
# Required-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description: Starts/Stops/Restarts the TeamSpeak 3 server
### END INIT INFO

# System Info
TS_USER=$TS3_USER
TS_ROOT_DIR=$TS3_DIR
TS_DAEMON=\$TS_ROOT_DIR/ts3server_startscript.sh

# Check if variables are set correctly
A=\$(cat /etc/passwd | grep -c \$TS_USER:)

if [ \$? -ne 0 ]; then
    echo -e "\nERROR!!! The user '\$TS_USER' does not exist!\n"
    exit 1
elif [ ! -d "\$TS_ROOT_DIR" ]; then
    echo -e "\nERROR!!! Your set directory '\$TS_ROOT_DIR' does not exist!\n"
    exit 1
elif [ ! -f "\$TS_DAEMON" ]; then
    echo -e "\nERROR!!! The daemon '\$TS_DAEMON' does not exist!\n"
    exit 1
fi

# Start TeamSpeak 3 server as set user
sudo -u \$TS_USER \$TS_DAEMON \$1

exit 0;
EOF

# initialize the ts3server to generate the ServerAdmin Privilege Key
chmod a+x /etc/init.d/ts3server
update-rc.d ts3server defaults >/dev/null 2>&1
echo "Starting the TeamSpeak 3 server..."
/etc/init.d/ts3server start >/tmp/ts3 2>&1
sleep 3

# finish
IMPORTANT=$(cat /tmp/ts3 | sed '1,3d;9,13d;/^$/d')
echo "$IMPORTANT" > $TS3_DIR/ServerAdmin_Privilege_Key.txt # save the important info for easy future reference, no need to search the logs
echo "ServerAdmin info saved to '$TS3_DIR/ServerAdmin_Privilege_Key.txt'"
echo -e "\n$IMPORTANT"
echo -e "\nCompleted! You should probably reboot the system now\n"
rm /tmp/ts3
exit 0