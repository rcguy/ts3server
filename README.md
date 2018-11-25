## Auto Install the Linux TeamSpeak 3 Server on Debian / Ubuntu
### What this script does:
- Creates a new user to run the TeamSpeak 3 Server
- Downloads and installs the server
- Creates a systemd service
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
To start, stop, restart, or check the status of the ts3-server use
```bash
sudo systemctl {start|stop|restart|status} ts3server 
```
