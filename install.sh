#!/bin/bash


printf "Welcome to watchgoat, let's install this motherfucker on your system.\n"


### What needs to be done?
# * Download needed files
# * Install netifaces
# * Check and create needed directories
# * Ask user for needed info
# * Make executable
# * Make executable, executable
# * Replace 'PATHTOEXECUTABLE' where needed and copy services to the right place
# * Start service



### DOWNLOAD NEEDED FILES ###


if [[ "$OSTYPE" == "darwin"* ]]
then
  printf "Running MacOS, going the launchd route"
  curl -O https://raw.githubusercontent.com/samsterckval/watchgoat/main/main.py
  curl -O https://raw.githubusercontent.com/samsterckval/watchgoat/main/launchd/com.samsterckval.watchgoat.plist
elif [[ "$OSTYPE" == "linux"* ]]
then
  printf "Running Linux, going the systemd route"
  curl -O https://raw.githubusercontent.com/samsterckval/watchgoat/main/main.py
  curl -O https://raw.githubusercontent.com/samsterckval/watchgoat/main/systemd/watchgoat.service
  curl -O https://raw.githubusercontent.com/samsterckval/watchgoat/main/systemd/watchgoat.timer
fi



### INSTALL NETIFACES ###


sudo -H pip install netifaces



### CHECK DIRECTORIES ###

BIN_DIR="$HOME/bin"
EXEC_NAME="watchgoat"
EXEC_DEST="$BIN_DIR/$EXEC_NAME"
INFO_DIR="$HOME/.watchgoat"
URL_FILE="watchgoat_urls"
URL_DEST="$INFO_DIR/$URL_FILE"
SECRETS_FILE="watchgoat_secrets"
SECRETS_DEST="$INFO_DIR/$SECRETS_FILE"


if [ ! -d "$BIN_DIR" ]
then
    printf "Bin directory %s doesn't exist. Creating now\n" "$BIN_DIR"
    mkdir "$BIN_DIR"
    printf "Created"
else
    printf "Bin directory %s already exists, did nothing yet\n" "$BIN_DIR"
fi

if [ ! -d "$INFO_DIR" ]
then
    printf "Info directory %s doesn't exist. Creating now\n" "$INFO_DIR"
    mkdir "$INFO_DIR"
    printf "Created"
else
    printf "Info directory %s already exist, did nothing yet\n" "$INFO_DIR"
fi



### ASK USER FOR NEEDED INFO ###


if [ ! -f "$URL_DEST" ]
then
    printf "Creating WatchGoat URL file @ %s\n" "$URL_DEST"
    touch "$URL_DEST"
    printf "Where did you deploy the WatchGoat server?  (e.g. https://mydomain.hosting.com/)\n"
    read -r BASEURL
    printf "%s/goat" "$BASEURL" >> "$URL_DEST"
else
    printf "WatchGoat URL file @ %s already exists, contents of it are not changed in any way\n" "$URL_DEST"
fi

if [ ! -f "$SECRETS_DEST" ]
then
    printf "Creating WatchGoat secrets file @ %s\n" "$SECRETS_DEST"
    touch "$SECRETS_DEST"
    printf "Username?\n"
    printf "Tip : If this is a Raspberry Pi, an NXP i.MX8(unconfirmed) or from the NVIDIA Jetson family, use 'rpi',\n"
    printf "for a device running MacOS, use 'mac'. This will translate to the unique serial number of the device.\n"
    printf "Else, just use a unique, recognisable name.\n"
    read -p "username : " USERNAME
    printf "Password?\n"
    read -p "password : " PASSWORD
#    printf "IP getter method?"
#    printf "For now, only 'netifaces' is supported, so this is a pseudo-choice, fuck you"
#    read -r IPMETHOD
    IPMETHOD="netifaces"
    printf "%s\n%s\n%s" "$USERNAME" "$PASSWORD" "$IPMETHOD" >> "$SECRETS_DEST"
else
    printf "WatchGoat secrets file @ %s already exists, contents of it are not changed in any way\n" "$SECRETS_DEST"
fi



### MAKE EXECUTABLE ###

sudo mv "main.py" "$EXEC_DEST"



### MAKE EXECUTABLE, EXECUTABLE ###

sudo chmod +x "$EXEC_DEST"


### REPLACE PATH, COPY & START SERVICES ###

if [[ "$OSTYPE" == "darwin"* ]]
then
  printf "Copying launchd service to %s/Library/LaunchAgents/ \n" "$HOME"
  sudo sed -i "s|PATHTOEXECUTABLE|$EXEC_DEST $URL_DEST $SECRETS_DEST|" "com.samsterckval.watchgoat.plist"
  sudo mv "com.samsterckval.watchgoat.plist" "$HOME/Library/LaunchAgents/com.samsterckval.watchgoat.plist"
  launchctl load com.samsterckval.watchgoat.plist
elif [[ "$OSTYPE" == "linux"* ]]
then
  printf "Copying systemd service & timer to /etc/systemd/system/ \n"
  sudo sed -i "s|PATHTOEXECUTABLE|$EXEC_DEST $URL_DEST $SECRETS_DEST|" "watchgoat.service"
  sudo mv "watchgoat.server" "/etc/systemd/system/watchgoat.service"
  sudo mv "watchgoat.timer" "/etc/systemd/system/watchgoat.timer"
  sudo systemctl daemon-reload
  sudo systemctl start watchgoat.timer
  sudo systemctl enable watchgoat.timer
fi


printf "All fucking done! Goat away you majestic beast!\n"

# Not going to throw this away, might come in handy in a few commits
# Absolute path to this script, e.g. /home/user/bin/foo.sh
#SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus e.g. /home/user/bin
#SCRIPTPATH=$(dirname "$SCRIPT")


