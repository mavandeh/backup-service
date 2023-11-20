# Backup Service

Creates backup service that backs up specified directories at the time of script run. To update, uninstall and reinstall.

## Files

### backup-service-install.sh

After cloning this repository, run `chmod +x backup-service-install.sh` and edit the following variables in the `cat` command blocks:

`'ARCHIVENAME="backup"` - this variable can be renamed to anything your heart desires. It will be the first string appended to the backup destination archive `ARCHIVEFULLPATH`.
`ARCHIVEPATH="/path/to/backup/destination"` - this is the path to where your archive will be stored.
`# After=network.target mnt-nas.mount` - this line will wait for a network share to mount. change `nas` to the name of the share in your `/mnt/` directory.

**NOTE:** 
- If you wish for `backup_script.sh` to be stored in a directory other than `/$HOME/.bin`, then you must edit these lines too, including those in `backup-service-uninstall.sh`
- If you wish for this script to be installed for all users, remove `--user` flag from the `systemd enable`, `systemd start`, and `systemd daemon-reload` commands at the end of the file. If you change this, you must also do the same to `backup-service-uninstall.sh`.

### backup-service-uninstall.sh

This script will uninstall the service regardless of modifcations made to the script. It will leave `backup_script.sh`.

## TODO:
- Add interactivity to install script that prompts user for install parameters, with suggested defaults:
    - Would you like to wait for network mount? Name of network mount? `# After=network.target mnt-nas.mount`
    - Where would you like the backup script to be stored and run from?
    - Enable for current user only, or all users of this machine?
    - How long to keep backups? (also periodic clearing of old backups)
    - Start and enable service/timer
    - Generate `backup-service-uninstall-user.sh` with same parameters.
- Create `backup-restore.sh` which:
    - lists unique archive names in backup directory, promts user to choose one.
    - lists last 10 dates backed up, prompts user to choose one.
    - untars archive to directory structure stored and prompts user to overwrite
