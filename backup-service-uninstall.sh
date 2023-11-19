#!/bin/bash

# Stop and disable the user timer
systemctl --user stop backup.timer
systemctl --user disable backup.timer

# Remove the user service and timer files
rm -f "$HOME/.config/systemd/user/backup.service" "$HOME/.config/systemd/user/backup.timer" "$HOME/.bin/backup_script.sh"

# Reload user systemd
systemctl --user daemon-reload

echo "Backup service and timer uninstalled successfully for the current user."
