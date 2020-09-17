#!/bin/bash
# Name: install_ts3-server.sh
# Version: 1.3
# Created On: 3/5/2015
# Updated On: 11/17/2019
# Created By: rcguy
# Description: Automagically installs the Linux TeamSpeak 3 Server
# Tested on: Debian 10 / x64 / VPS / 2 Cores / 2GB RAM / 20 GB SSD

# ==> VARIABLES <==
# user to run the ts3server and where to install it
TS3_USER="teamspeak3"
TS3_DIR="/opt/ts3server"
TS3_VER="3.12.1"

# ==> MAIN PROGRAM <==
set -e # exit with a non-zero status when there is an uncaught error

# are we root?
if  [ "$EUID" -ne 0 ]; then
  echo -e "\nERROR!!! SCRIPT MUST RUN WITH ROOT PRIVILAGES\n"
  exit 1
fi

# official download urls - updated on: 11/17/2019
X86="https://files.teamspeak-services.com/releases/server/$TS3_VER/teamspeak3-server_linux_x86-$TS3_VER.tar.bz2"
X64="https://files.teamspeak-services.com/releases/server/$TS3_VER/teamspeak3-server_linux_amd64-$TS3_VER.tar.bz2"

# check if we need 64bit or 32bit binaries
A=$(arch)
if [ "$A" = "x86_64" ]; then
  URL="$X64"
elif [ "$A" = "i386" ]; then
  URL="$X86"
elif [ "$A" = "i686" ]; then
  URL="$X86"
fi

# functions
function install_ts3-server {
mkdir -p "$TS3_DIR"
touch "$TS3_DIR"/.ts3server_license_accepted
tar -xjf teamspeak3-server_linux*.tar.bz2
mv teamspeak3-server_linux*/* "$TS3_DIR"
chown "$TS3_USER":"$TS3_USER" "$TS3_DIR" -R
rm -rf teamspeak3-server_linux*.tar.bz2 teamspeak3-server_linux*/
}

# add the user to run ts3server
if adduser --system --group --disabled-login --disabled-password --no-create-home "$TS3_USER" >/dev/null 2>&1; then
  echo -e "\nAdded new user: '$TS3_USER'"
else
  echo -e "\n ERROR!!! Failed to add new user: '$TS3_USER'\n"
  exit 1
fi

# download and install the ts3server
echo "Installing the TeamSpeak 3 server to: '$TS3_DIR'"
if wget -q "$URL"; then
  install_ts3-server
else
  echo -e "\n ERROR!!! Failed to download the TeamSpeak 3 server\n"
  exit 1
fi

# install the init.d start-up script
touch /etc/systemd/system/ts3server.service
cat > /etc/systemd/system/ts3server.service <<EOF
[Unit]
Description=TeamSpeak3 Server
Wants=network-online.target
After=syslog.target network.target

[Service]
WorkingDirectory= $TS3_DIR
User=$TS3_USER
Group=$TS3_USER
Type=forking
ExecStart= $TS3_DIR/ts3server_startscript.sh start inifile= $TS3_DIR/ts3server.ini
ExecStop= $TS3_DIR/ts3server_startscript.sh stop
ExecReload= $TS3_DIR/ts3server_startscript.sh reload
PIDFile= $TS3_DIR/ts3server.pid

[Install]
WantedBy=multi-user.target
EOF

# install a default ts3server.ini
touch "$TS3_DIR"/ts3server.ini
cat > "$TS3_DIR"/ts3server.ini <<EOF
#The path of the *.ini file to use.
inifile=ts3server.ini

# The Voice IP that your Virtual Servers are listing on. [UDP] (Default: 0.0.0.0)
voice_ip=0.0.0.0

# The Query IP that your Instance is listing on. [TCP] (Default: 0.0.0.0)
query_ip=0.0.0.0

# The Filetransfer IP that your Instance is listing on. [TCP] (Default: 0.0.0.0)
filetransfer_ip=

# The Voice Port that your default Virtual Server is listing on. [UDP] (Default: 9987)
default_voice_port=9987

# The Query Port that your Instance is listing on. [TCP] (Default: 10011)
query_port=10011

# The Filetransfer Port that your Instance is listing on. [TCP] (Default: 30033)
filetransfer_port=30033

# Use the same log file
logappend=1
EOF
chown "$TS3_USER":"$TS3_USER" "$TS3_DIR"/ts3server.ini

# start the ts3server to generate the ServerAdmin Privilege Key
echo "Starting the TeamSpeak 3 server"
systemctl --quiet enable ts3server.service
systemctl start ts3server.service
sleep 5

# finish
EXTERNAL_IP=$(wget -qO - http://geoip.ubuntu.com/lookup | sed -n -e 's/.*<Ip>\(.*\)<\/Ip>.*/\1/p')
IMPORTANT=$(cat "$TS3_DIR"/logs/*_1.log | grep -P -o "token=[a-zA-z0-9+]+")
echo "$IMPORTANT" > "$TS3_DIR"/ServerAdmin_Privilege_Key.txt # save the ServerAdmin Privilege Key for easy future reference
echo -e "\nServerAdmin info saved to: '$TS3_DIR/ServerAdmin_Privilege_Key.txt'"
echo -e "ServerAdmin Privilege Key: $IMPORTANT\n"
echo -e "Completed! You should probably configure the server now\nUse the desktop client for easy administration\n"
echo -e "Your servers external IP Address is: $EXTERNAL_IP\n"
exit 0
