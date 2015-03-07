#!/bin/bash
# Name: install_ts3-server.sh
# Version: 1.0
# Created On: 3/5/2015
# Created By: rcguy
# Description: Automagically installs the Linux TeamSpeak 3 Server
# Tested on: Ubuntu Server 14.10 / x64 / x86 / VPS / 2 Cores / 2GB RAM / 20 GB SSD

# ==> USER VARIABLES <==
# user to run the ts3server and where to install it
TS3_USER="teamspeak3"
TS3_DIR="/opt/ts3-server"
TS3_START_OPTIONS="" # Example: "default_voice_port=1234 voice_ip=111.222.333.444"

# ==> MAIN PROGRAM <==
set -e # exit with a non-zero status when there is an uncaught error

# are we root?
if	[ "$EUID" -ne 0 ]; then
	echo -e "\nERROR!!! SCRIPT MUST RUN WITH ROOT PRIVILAGES\n"
	exit 1
fi

# official download urls - updated on: 3/7/2015
X64_M1="http://dl.4players.de/ts/releases/3.0.11.2/teamspeak3-server_linux-amd64-3.0.11.2.tar.gz"
X64_M2="http://teamspeak.gameserver.gamed.de/ts3/releases/3.0.11.2/teamspeak3-server_linux-amd64-3.0.11.2.tar.gz"
X86_M1="http://dl.4players.de/ts/releases/3.0.11.2/teamspeak3-server_linux-x86-3.0.11.2.tar.gz"
X86_M2="http://teamspeak.gameserver.gamed.de/ts3/releases/3.0.11.2/teamspeak3-server_linux-x86-3.0.11.2.tar.gz"

# check if we need 64bit or 32bit binaries
A=$(arch)
if [ "$A" = "x86_64" ]; then
	URL1="$X64_M1"
	URL2="$X64_M2"
elif [ "$A" = "i386" ]; then
	URL1="$X86_M1"
	URL2="$X86_M2"
elif [ "$A" = "i686" ]; then
	URL1="$X86_M1"
	URL2="$X86_M2"
fi

# functions
function install_ts3-server {
mkdir -p $TS3_DIR
tar -xzf teamspeak3-server_linux*.tar.gz
mv teamspeak3-server_linux*/* $TS3_DIR
chown $TS3_USER:$TS3_USER $TS3_DIR -R
rm -rf teamspeak3-server_linux*.tar.gz teamspeak3-server_linux-*/
}

# add the user to run ts3server
if adduser --system --group --disabled-login --disabled-password --no-create-home $TS3_USER >/dev/null 2>&1; then
	echo -e "\nAdded new user: '$TS3_USER'"
else
	echo -e "\n ERROR!!! Failed to add new user: '$TS3_USER'\n"
	exit 1
fi

# download and install the ts3server
echo "Installing the TeamSpeak 3 server to: '$TS3_DIR'"
if wget -q $URL1; then
	install_ts3-server
elif wget -q $URL2; then
	install_ts3-server
else
	echo -e "\n ERROR!!! Failed to download the TeamSpeak 3 server\n"
	exit 1
fi

# install the init.d start-up script
touch /etc/init.d/ts3server
cat > /etc/init.d/ts3server <<EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides: ts3server
# Required-Start: \$network
# Required-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description: Runs the ts3server_startscript.sh as the user defined below
### END INIT INFO

# Variables
TS_USER=$TS3_USER
TS_DAEMON=$TS3_DIR/ts3server_startscript.sh
TS_OPTIONS="$TS3_START_OPTIONS"

# Check if variables are set correctly
A=\$(cat /etc/passwd | grep -c \$TS_USER:)

if [ \$? -ne 0 ]; then
    echo -e "\n ERROR!!! The user '\$TS_USER' does not exist!\n"
    exit 1
elif [ ! -f "\$TS_DAEMON" ]; then
    echo -e "\n ERROR!!! The daemon '\$TS_DAEMON' does not exist!\n"
    exit 1
fi

# Start the server
sudo -u \$TS_USER \$TS_DAEMON \$1 \$TS_OPTIONS

exit 0;
EOF

# start the ts3server to generate the ServerAdmin Privilege Key
chmod a+x /etc/init.d/ts3server
update-rc.d ts3server defaults >/dev/null 2>&1
echo "Starting the TeamSpeak 3 server..."
/etc/init.d/ts3server start >/tmp/ts3 2>&1
sleep 3

# finish
EXTERNAL_IP=$(wget -qO - http://geoip.ubuntu.com/lookup | sed -n -e 's/.*<Ip>\(.*\)<\/Ip>.*/\1/p')
IMPORTANT=$(cat /tmp/ts3 | sed '1,3d;9,13d;/^$/d')
echo "$IMPORTANT" > $TS3_DIR/ServerAdmin_Privilege_Key.txt # save the ServerAdmin Privilege Key for easy future reference
echo "ServerAdmin info saved to: '$TS3_DIR/ServerAdmin_Privilege_Key.txt'"
echo -e "\n$IMPORTANT\n"
echo -e "Completed! You should probably configure the server now\nUse the desktop client for easy administration"
echo -e "Your servers external IP Address is: '$EXTERNAL_IP'\n"
rm /tmp/ts3
exit 0