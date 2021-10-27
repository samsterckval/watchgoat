#!/bin/sh

echo "Installing WatchGoat"       # Just some random print to know it actually starts

curl -O https://raw.githubusercontent.com/samsterckval/watchgoat/main/main.py
curl -O https://raw.githubusercontent.com/samsterckval/watchgoat/main/systemd/watchgoat.service
curl -O https://raw.githubusercontent.com/samsterckval/watchgoat/main/systemd/watchgoat.timer

sudo -H pip install netifaces

BIN_DIR="bin"
EXEC_NAME="watchgoat"
DEST="$HOME/$BIN_DIR/$EXEC_NAME"
INFO_DIR=".watchgoat"
URL_FILE="watchgoat_urls"
SECRETS_FILE="watchgoat_secrets"


if [ ! -d "$HOME/$BIN_DIR" ]
then
    echo "Bin folder doesn't exist. Creating now"
    mkdir "$HOME/$BIN_DIR"
    echo "Folder created"
else
    echo "Bin folder already exists"
fi

if [ ! -d "$HOME/$INFO_DIR" ]
then
    echo "Info directory doesn't exist. Creating now"
    mkdir "$HOME/$INFO_DIR"
    echo "Folder created"
else
    echo "Info folder already exists"
fi

if [ ! -f "$HOME/$INFO_DIR/$URL_FILE" ]
then
    echo "Creating WatchGoat URL file with base URL"
    echo "Where did you deploy the WatchGoat server?"
    touch "$HOME/$INFO_DIR/$URL_FILE"
    read -r BASEURL
    printf "%s/goat" "$BASEURL" >> "$HOME/$INFO_DIR/$URL_FILE"
else
    echo "WatchGoat URL file already exists, contents of it are not changed in any way"
fi

if [ ! -f "$HOME/$INFO_DIR/$SECRETS_FILE" ]
then
    echo "Creating WatchGoat secrets file"
    touch "$HOME/$INFO_DIR/$SECRETS_FILE"
    echo "Username?"
    echo "Tip : If this is a Raspberry Pi, an NXP i.MX8 or from the NVIDIA Jetson family, use 'rpi',"
    echo "for a mac, use 'mac'. This will translate to the unique serial number of the device."
    read -r USERNAME
    echo "Password?"
    read -r PASSWORD
    printf "%s\n%s" "$USERNAME" "$PASSWORD" >> "$HOME/$INFO_DIR/$SECRETS_FILE"
else
    echo "WatchGoat secrets file already exists, contents of it are not changed in any way"
fi

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus e.g. /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

echo "Path to this script : $SCRIPTPATH"

# Create symbolic link -- We don't do that anymore
#ln -s "$SCRIPTPATH/main.py" "$DEST"

# Move and rename the main python script
sudo mv "main.py" "$DEST"

# We don't do this either anymore
#echo "Symbolic link created for $SCRIPTPATH/main.py @ $DEST"

# Make the link executable
chmod +x "$DEST"

echo "Made $DEST executable"

# Copy systemd services
#sudo cp "$SCRIPTPATH/systemd/watchgoat.service" "/etc/systemd/system/watchgoat.service"
#sudo cp "$SCRIPTPATH/systemd/watchgoat.timer" "/etc/systemd/system/watchgoat.timer"

# These should be downloaded with curl
sudo mv "watchgoat.server" "/etc/systemd/system/watchgoat.service"
sudo mv "watchgoat.timer" "/etc/systemd/system/watchgoat.timer"

echo "Copied files to /etc/systemd/system/"

sudo sed -i "s|PATHTOEXECUTABLE|$DEST $HOME/$INFO_DIR/$URL_FILE $HOME/$INFO_DIR/$SECRETS_FILE|" "/etc/systemd/system/watchgoat.service"

cat "/etc/systemd/system/watchgoat.service"

# Reload deamons
sudo systemctl daemon-reload
echo "Reloaded systemctl"

# Start it to be sure?
sudo systemctl start watchgoat.timer
echo "Started watchgoat"

# Enable timer by default
sudo systemctl enable watchgoat.timer
echo "Enabled watchgoat"


