#!/bin/bash

# Synology drive has POSIX file system, which combined with SMB
# mangles macOS names containing "*" "/" or ":".
# Final Cut and other apps automatically create these, so need to accept UTF-8
# for backup to not keep trying to re-write already existing files.


TOOLCHAIN_URL="https://global.synologydownload.com/download/ToolChain/toolchain/7.2-72746/Intel%20x86%20Linux%204.4.302%20%28GeminiLake%29/geminilake-gcc1220_glibc236_x86_64-GPL.txz"
TOOLCHAIN_FILE="${TOOLCHAIN_URL##*/}"
EXTRACT_DIR="${TOOLCHAIN_FILE%.txz}"
I18N_PATH="/usr/share/i18n"
LOCALE_PATH="/usr/lib/locale"
PASSWORD="$1"

if [[ -z "$PASSWORD" ]]; then
    echo "Usage: $0 <sudo-password>"
    exit 1
fi

# Ensure the toolchain file exists
if [[ ! -f "$TOOLCHAIN_FILE" ]]; then
    echo "Downloading toolchain..."
    wget "$TOOLCHAIN_URL" || { echo "Download failed."; exit 1; }
else
    echo "Toolchain package already exists, skipping download."
fi

# Extract only if the directory doesn't exist
if [[ -d "$EXTRACT_DIR" ]]; then
    echo "Toolchain already extracted, skipping extraction."
else
    echo "Extracting toolchain..."
    mkdir "$EXTRACT_DIR"
    tar -xJf "$TOOLCHAIN_FILE" -C "$EXTRACT_DIR" --strip-components=1 || { echo "Extraction failed."; exit 1; }
fi

# Copy necessary locale files
echo "$PASSWORD" | sudo -S mkdir -p "$I18N_PATH/charmaps" "$I18N_PATH/locales" "$LOCALE_PATH"
echo "$PASSWORD" | sudo -S cp -r "$EXTRACT_DIR/x86_64-pc-linux-gnu/sys-root/usr/share/i18n/"* "$I18N_PATH/" || { echo "Copying i18n files failed."; exit 1; }

# Generate and set locale
echo "$PASSWORD" | sudo -S localedef -f UTF-8 -i en_US en_US.UTF-8 || { echo "Failed to generate locale."; exit 1; }

# Ensure profile settings are updated
echo "$PASSWORD" | sudo -S sed -i '/^export LANG=/d' /etc/profile
echo "$PASSWORD" | sudo -S sed -i '/^export LC_ALL=/d' /etc/profile
echo "$PASSWORD" | sudo -S bash -c "echo 'export LANG=en_US.UTF-8' >> /etc/profile"
echo "$PASSWORD" | sudo -S bash -c "echo 'export LC_ALL=en_US.UTF-8' >> /etc/profile"

echo "Locale setup complete."