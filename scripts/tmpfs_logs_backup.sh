#!/bin/bash

# Define log directories (tmpfs)
LOG_DIRS=(
    "/volume1/docker/sonarr/logs"
    "/volume1/docker/plex/Library/Application Support/Plex Media Server/Logs"
    "/volume1/docker/prowlarr/logs"
    "/volume1/docker/radarr/logs"
    "/volume1/docker/bazarr/log"
    "/volume1/docker/readarr/logs"
    "/volume1/docker/overseerr/logs"
)

# Name for the saved logs directory
SAVED_LOGS_DIR="saved-logs"

# Number of days to retain logs
RETENTION_DAYS=30

# Define a single log file that will be overwritten each time
LOG_FILE="/var/log/tmpfs_logs_backup.log"

# Timestamp for logging
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Overwrite the log file for each run
exec > "$LOG_FILE" 2>&1

echo "[$TIMESTAMP] Starting log backup process..."

# Backup each log directory to its respective saved-logs location
for LOG_DIR in "${LOG_DIRS[@]}"; do
    if [ -d "$LOG_DIR" ]; then
        # Determine the parent directory of the log directory
        PARENT_DIR=$(dirname "$LOG_DIR")

        # Set the backup directory inside the same parent directory
        BACKUP_DIR="$PARENT_DIR/$SAVED_LOGS_DIR"

        # Ensure the backup directory exists
        mkdir -p "$BACKUP_DIR"

        # Rsync logs, replacing existing ones
        rsync -a --delete "$LOG_DIR/" "$BACKUP_DIR/"

        echo "[$TIMESTAMP] Synced logs from $LOG_DIR to $BACKUP_DIR"

        # Remove logs older than the retention period from the backup
        find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete
        echo "[$TIMESTAMP] Removed logs older than $RETENTION_DAYS from $BACKUP_DIR"

        # Remove logs older than the retention period from the tmpfs source
        find "$LOG_DIR" -type f -mtime +$RETENTION_DAYS -delete
        echo "[$TIMESTAMP] Removed logs older than $RETENTION_DAYS from $LOG_DIR"

    else
        echo "[$TIMESTAMP] WARNING: Log directory $LOG_DIR does not exist."
    fi
done

echo "[$TIMESTAMP] Log backup process completed."