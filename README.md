##Auto Install the Linux TeamSpeak 3 Server
### What this script does:
- Creates a new user to run the TeamSpeak 3 Server
- Downloads and installs the server
- Creates an init.d startup script
- Starts the server

### How to use:
Download or copy the script and paste it into a new file
```bash
wget https://raw.githubusercontent.com/rcguy/install_ts3-server/master/install_ts3-server.sh
```
Change the user variables if necessary
```bash
nano install_ts3-server.sh
```
Make the script executable
```bash
chmod a+x install_ts3-server.sh
```
Run the script
```bash
sudo ./install_ts3-server.sh
```
