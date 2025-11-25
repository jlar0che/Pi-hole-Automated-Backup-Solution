#!/bin/bash

# ---------------------
# Pi-hole backup v0.6.3
# Jacques_Laroche
# ---------------------

# Define variables
# ----------------
BACKUP_DIR="/home/pi/Pihole_Backups"  # Directory on your Pi-hole where backups will be stored
NAS_DIR="/volume1/Backups/Pi-hole"  # The destination directory on your NAS / other backup device
LOG_FILE="/home/pi/Pihole_Backups/logs/logfile.log"  # Log file to track script activity. This is on your Pi-hole.
NAS_USER="your-admin-username"  # NAS / Backup Destination username
NAS_HOST="192.168.1.100"  # NAS / Backup Destination IP address
NAS_PORT=22  # The SSH port used by the NAS / Backup Destination

# Begin Log demarcation
# ---------------------
echo "=====[ BEGIN BACKUP LOG ENTRY ]==================" >> "$LOG_FILE"

# Create a backup
# ---------------
cd "$BACKUP_DIR" || { echo "Backup directory not found!" >> "$LOG_FILE"; exit 1; }

echo "$(date '+%Y-%m-%d %H:%M:%S') - Running Pi-hole backup" >> "$LOG_FILE"
pihole-FTL --teleporter # This command automatically creates the backup file in Pi-Hole v6.x

# Find the most recently created Pi-hole backup file
# --------------------------------------------------
BACKUP_FILE=$(ls -t pi-hole-*.tar.gz | head -n 1)

if [ -n "$BACKUP_FILE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup successful: $BACKUP_FILE" >> "$LOG_FILE"
    
    # Retain only the 4 most recent backups (force delete without prompts)
	# --------------------------------------------------------------------
    BACKUPS_TO_DELETE=$(ls -tp *.tar.gz | grep -v '/$' | tail -n +5)  # List backups, keeping 4 newest
    if [ ! -z "$BACKUPS_TO_DELETE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Deleting old backups:" >> "$LOG_FILE"
        echo "- [DELETING] $BACKUPS_TO_DELETE" >> "$LOG_FILE"
        rm -f $BACKUPS_TO_DELETE  # Force delete without asking for confirmation
    fi

    # Sync only .tar.gz files to NAS / Destination Device using rsync, (redirect stdout & stderr to Log file)
	# -----------------------------------------------------------------------------------
    echo "$(date '+%Y-%m-%d %H:%M:%S') --> Syncing backups to NAS" >> "$LOG_FILE"
    rsync -av --include="*/" --include="*.tar.gz" --exclude="*" --delete -e "ssh -p $NAS_PORT" "$BACKUP_DIR" "$NAS_USER@$NAS_HOST:$NAS_DIR" >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Sync successful" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Sync failed!" >> "$LOG_FILE"
    fi
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup failed: No backup file found!" >> "$LOG_FILE"
fi

# Add a demarcation line to mark the end of the primary backup operations
# -----------------------------------------------------------------------
echo "------ [END of BACKUP AND SYNC] ------" >> "$LOG_FILE"

# Sync the logs directory to NAS after everything is complete
# -----------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') - Syncing logs to NAS" >> "$LOG_FILE"
rsync -av -e "ssh -p $NAS_PORT" "$BACKUP_DIR/logs/" "$NAS_USER@$NAS_HOST:$NAS_DIR/logs/" >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Logs sync successful" >> "$LOG_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Logs sync failed!" >> "$LOG_FILE"
fi

# Add a final demarcation line to mark the end of the script
# ----------------------------------------------------------
echo "------ [END of LOGS SYNC] ------" >> "$LOG_FILE"
echo "=====[ END BACKUP LOG ENTRY ]====================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Sync the log file once more (so info written to logs after last rsync are also synced
# -------------------------------------------------------------------------------------
rsync -av -e "ssh -p $NAS_PORT" "$BACKUP_DIR/logs/" "$NAS_USER@$NAS_HOST:$NAS_DIR/logs/" > /dev/null 2>&1
