#!/bin/bash

set -e

########################################
# CONFIGURATION (EDIT THESE VARIABLES)
########################################

# Local backup directory
LOCAL_BACKUP_DIR="/path/to/local/backups"

# Remote NAS settings
REMOTE_USER="username"
REMOTE_HOST="192.168.x.x"
REMOTE_DIR="/path/to/remote/backups"

# Log file
LOG_FILE="/path/to/logfile.log"

########################################
# START
########################################

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="pi-hole_backup_${TIMESTAMP}.zip"
BACKUP_PATH="${LOCAL_BACKUP_DIR}/${BACKUP_NAME}"

echo "$(date) --> Starting Pi-hole backup" >> "$LOG_FILE"

########################################
# CREATE BACKUP
########################################

pihole -a teleporter "${BACKUP_PATH}"

echo "$(date) --> Backup created: ${BACKUP_NAME}" >> "$LOG_FILE"

########################################
# CLEAN OLD BACKUPS (KEEP LAST 5)
########################################

cd "$LOCAL_BACKUP_DIR"
ls -t *.zip | tail -n +6 | while read file; do
    echo "$(date) --> Deleting old backup: $file" >> "$LOG_FILE"
    rm -f "$file"
done

########################################
# SYNC TO REMOTE NAS
########################################

echo "$(date) --> Syncing backups to remote storage" >> "$LOG_FILE"

rsync -av --delete \
    "${LOCAL_BACKUP_DIR}/" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" \
    >> "$LOG_FILE" 2>&1

echo "$(date) --> Sync completed" >> "$LOG_FILE"

########################################
# END
########################################
