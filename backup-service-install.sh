#!/bin/bash

# TODO/FIXME: Prompt user for list of directories to back up, accept from file or arguments

# prompt user for archive name
echo "Enter a descriptive filename for your archive (default: backup):"
read ARCHIVENAME
ARCHIVENAME="${ARCHIVENAME:-backup}"

echo "Enter the full path that the archive will be saved (default: \$HOME/.backups):"
read ARCHIVEPATH
ARCHIVEPATH="${ARCHIVEPATH:-$HOME/.backups}"

echo "How often would you like backups to occur? (hourly|daily|weekly|monthly [default: daily]):"
read SCHEDULE
SCHEDULE="${SCHEDULE:-daily}"

if [[ "$SCHEDULE" =~ ^(hourly|daily|weekly|monthly)$ ]]; then
    echo -n
else
    echo "$SCHEDULE is not a valid schedule argument (hourly|daily|weekly|monthly). Exiting."
    exit 1
fi

# TODO/FIXME: Prompt whether to install for user or all users -- commented out because this is buggy.
# echo "Would you like to install this for current user or all users? (current|all [default: current]):"
# read CURRENTUSER
CURRENTUSER=${CURRENTUSER:-current}
if [[ "$CURRENTUSER" =~ ^(current)$ ]]; then
    echo "Archive $ARCHIVENAME will be saved to $ARCHIVEPATH on $SCHEDULE schedule for $CURRENTUSER user."
    USERARG="--user"
elif [[ "$CURRENTUSER" =~ ^(all)$ ]]; then
    echo "Archive $ARCHIVENAME will be saved to $ARCHIVEPATH on $SCHEDULE schedule for $CURRENTUSER users."
    USERARG=""
else
    echo "$CURRENTUSER is not a valid schedule argument (hourly|daily|weekly|monthly). Exiting."
    exit 1
fi

# Create the backup script in the user's home directory
cat <<EOF | tee "$HOME/.bin/backup_script.sh" > /dev/null
#!/bin/bash
DATE=\`date '+%Y%m%d-%H%M%S'\`

# directory you want to backup
BACKUPPATHS=(
    "\$HOME/.bin"
    "\$HOME/.config/fish"
    "\$HOME/.config/systemd"
    "\$HOME/.config/MangoHud"
    "\$HOME/.config/starship.toml"
    "\$HOME/.bashrc"
    "\$HOME/.bash_profile"
    "\$HOME/.bash_logout"
    "\$HOME/.bash_history"
    "\$HOME/start-virtual-console.sh"
    "/path/to/more/backups"
)

# Full path, including filename, of your backup
ARCHIVEFULLPATH="$ARCHIVEPATH/$ARCHIVENAME-\$DATE.tar.gz"

# Does the directory not exist? If not, create it.
[ ! -d $ARCHIVEPATH ] && mkdir $ARCHIVEPATH

echo \$ARCHIVEFULLPATH
sleep 5

# tarball the backup directory and store in ARCHIVEFULLPATH
tar --exclude='screenshots' -cvzpf \$ARCHIVEFULLPATH "\${BACKUPPATHS[@]}"
EOF

chmod +x "$HOME/.bin/backup_script.sh"

# Create the service file in the user's systemd user directory
mkdir -p "$HOME/.config/systemd/user"
cat <<EOF | tee "$HOME/.config/systemd/user/backup.service" > /dev/null
[Unit]
Description=Backup Service
# After=network.target mnt-$MOUNTDIR.mount 

[Service]
Type=oneshot
ExecStart=/bin/bash $HOME/.bin/backup_script.sh
EOF

# Create the timer file in the user's systemd user directory
cat <<EOF | tee "$HOME/.config/systemd/user/backup.timer" > /dev/null
[Unit]
Description=Timer for Backup Service

[Timer]
OnCalendar=$SCHEDULE
Persistent=true
Unit=backup.service

[Install]
WantedBy=default.target
EOF

# Create the uninstall script in the current directory
cat <<EOF | tee "backup-service-uninstall-user.sh" > /dev/null
#!/bin/bash

# Stop and disable the user timer
systemctl $USERARG stop backup.timer
systemctl $USERARG disable backup.timer

# Remove the user service and timer files
rm -f "$HOME/.config/systemd/user/backup.service" "$HOME/.config/systemd/user/backup.timer"

# Reload user systemd
systemctl $USERARG daemon-reload

echo "Backup service and timer uninstalled successfully for the current user."
EOF

# Reload user systemd
systemctl $USERARG daemon-reload

# Enable and start the user timer
systemctl $USERARG enable --now backup.timer
systemctl $USERARG start backup.service

echo "Backup service installed successfully for the current user. Check your backup destination to see if it ran correctly, and troubleshoot with:"
echo "journalctl $USERARG -xeu backup"
echo "systemctl $USERARG status backup"

exit 0