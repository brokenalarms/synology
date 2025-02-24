#!/bin/bash

# this is a hack/extra work to try and make your NAS shut up
# no need if you have an SSD cache installed.

# Define tmpfs mount names, paths, and initial sizes
declare -A TMPFS_MOUNTS=(
    ["sonarr-cache"]="/volume1/docker/sonarr/logs"
    ["plex-cache"]="/volume1/docker/plex/Library/Application Support/Plex Media Server/Logs"
    ["prowlarr-cache"]="/volume1/docker/prowlarr/logs"
    ["radarr-cache"]="/volume1/docker/radarr/logs"
    ["bazarr-cache"]="/volume1/docker/bazarr/log"
    ["readarr-cache"]="/volume1/docker/readarr/logs"
    ["overseerr-cache"]="/volume1/docker/overseerr/logs"
)

# Define sizes for each mount
declare -A TMPFS_SIZES=(
    ["sonarr-cache"]="10M"
    ["plex-cache"]="10M"
    ["prowlarr-cache"]="10M"
    ["radarr-cache"]="10M"
    ["bazarr-cache"]="10M"
    ["readarr-cache"]="10M"
    ["overseerr-cache"]="10M"
)

# User and group IDs for ownership
UID=1031
GID=65337

# Log file
LOG_FILE="/var/log/tmpfs_logs_mount.log"

# Maximum allowed tmpfs size
MAX_TMPFS_SIZE=100

# Timestamp for logging
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Overwrite log file on each boot
exec > "$LOG_FILE" 2>&1

echo "[$TIMESTAMP] Starting tmpfs mount process..."

# Function to check if a directory is already mounted
is_mounted() {
    grep -qs " $1 " /proc/mounts
}

# Ensure tmpfs mounts exist with correct size
for MOUNT_NAME in "${!TMPFS_MOUNTS[@]}"; do
    MOUNT_POINT="${TMPFS_MOUNTS[$MOUNT_NAME]}"
    SIZE="${TMPFS_SIZES[$MOUNT_NAME]}"
"../scripts/tmpfs_logs_mount.sh" 96L, 3139B                                                                                                                            1,1           Top
}

# Ensure tmpfs mounts exist with correct size
for MOUNT_NAME in "${!TMPFS_MOUNTS[@]}"; do
    MOUNT_POINT="${TMPFS_MOUNTS[$MOUNT_NAME]}"
    SIZE="${TMPFS_SIZES[$MOUNT_NAME]}"
    SIZE_MB=$(echo "$SIZE" | sed 's/M//')

    # Ensure parent directory exists
    mkdir -p "$MOUNT_POINT"

    # Get current log directory usage
    CURRENT_USAGE=$(du -sm "$MOUNT_POINT" 2>/dev/null | awk '{print $1}')
    CURRENT_USAGE=${CURRENT_USAGE:-0}  # Default to 0 if du fails

    # Check if logs are exceeding tmpfs allocation
    if (( CURRENT_USAGE > SIZE_MB )); then
        echo "[$TIMESTAMP] WARNING: Log directory $MOUNT_POINT exceeds tmpfs allocation ($CURRENT_USAGE MB > $SIZE_MB MB)."

        # Remove logs older than 30 days in tmpfs to free space
        find "$MOUNT_POINT" -type f -mtime +30 -delete

        # Recalculate usage after cleanup
        CURRENT_USAGE=$(du -sm "$MOUNT_POINT" 2>/dev/null | awk '{print $1}')
        CURRENT_USAGE=${CURRENT_USAGE:-0}

        # If still oversized, increase tmpfs size
        if (( CURRENT_USAGE > SIZE_MB )); then
            NEW_SIZE=$(( SIZE_MB * 2 ))
            if (( NEW_SIZE > MAX_TMPFS_SIZE )); then
                NEW_SIZE=$MAX_TMPFS_SIZE
            fi
            echo "[$TIMESTAMP] WARNING: Even after cleanup, $MOUNT_POINT is still over limit ($CURRENT_USAGE MB)."
            echo "[$TIMESTAMP] Increasing tmpfs size to ${NEW_SIZE}M."

            # Remount with new size
            sudo mount -o remount,size=${NEW_SIZE}M "$MOUNT_POINT"
        fi
    fi

    # Check if already mounted correctly
    if is_mounted "$MOUNT_POINT"; then
        echo "[$TIMESTAMP] Already mounted: $MOUNT_POINT"
    else
        # Mount tmpfs with correct size
        mount -t tmpfs -o size=$SIZE,mode=0777,uid=$UID,gid=$GID "$MOUNT_NAME" "$MOUNT_POINT"
        echo "[$TIMESTAMP] Mounted tmpfs: $MOUNT_NAME -> $MOUNT_POINT with size $SIZE"
    fi
done

echo "[$TIMESTAMP] Tmpfs mount process completed."
