#!/bin/bash

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
    "/more/paths/to/backup"
)

# Name of your archive (will append date later)
ARCHIVENAME="backup"

# Directory path to your backups
ARCHIVEPATH="/path/to/backup/destination"

# Full path, including filename, of your backup
ARCHIVEFULLPATH="\$ARCHIVEPATH/\$ARCHIVENAME-\$DATE.tar.gz"

# Does the directory not exist? If not, create it.
[ ! -d \$ARCHIVEPATH ] && mkdir \$ARCHIVEPATH

echo \$ARCHIVEFULLPATH
sleep 5

# tarball the backup directory and store in ARCHIVEFULLPATH
# --exclude 'screenshots' for backing up final fantasy xiv configs directory
tar --exclude='screenshots' -cvzpf \$ARCHIVEFULLPATH "\${BACKUPPATHS[@]}"
EOF

chmod +x "$HOME/.bin/backup_script.sh"

# Create the service file in the user's systemd user directory
mkdir -p "$HOME/.config/systemd/user"
cat <<EOF | tee "$HOME/.config/systemd/user/backup.service" > /dev/null
[Unit]
Description=Backup Service
# After=network.target mnt-nas.mount # uncomment this line to wait for a network mount

[Service]
Type=oneshot
ExecStart=/bin/bash $HOME/.bin/backup_script.sh
EOF

# Create the timer file in the user's systemd user directory
cat <<EOF | tee "$HOME/.config/systemd/user/backup.timer" > /dev/null
[Unit]
Description=Timer for Backup Service

[Timer]
OnCalendar=daily
Persistent=true
Unit=backup.service

[Install]
WantedBy=default.target
EOF

# Reload user systemd
systemctl --user daemon-reload

# Enable and start the user timer
systemctl --user enable --now backup.timer
systemctl --user start backup.service

echo "Backup service installed successfully for the current user. Check your backup destination to see if it ran correctly, and troubleshoot with:"
echo "journalctl --user -xeu backup"
echo "systemctl --user status backup"