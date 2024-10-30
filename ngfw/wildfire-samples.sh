#!/bin/bash

# Set download directory
DOWNLOAD_DIR="/var/tmp/.hidden_wildfire_samples"

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Function to download a file and verify success
download_file() {
    local url=$1
    local filename=$2

    echo "Downloading $filename..."

    # Check if wget or curl is available
    if command -v wget &> /dev/null; then
        wget -q "$url" -O "$DOWNLOAD_DIR/$filename"
    elif command -v curl &> /dev/null; then
        curl -s "$url" -o "$DOWNLOAD_DIR/$filename"
    else
        echo "Neither wget nor curl is available. Cannot download $filename."
        return 1
    fi

    if [ $? -eq 0 ]; then
        echo "$filename downloaded successfully."
        chmod +x "$DOWNLOAD_DIR/$filename"
    else
        echo "Failed to download $filename."
    fi
}

# URLs to download from
PE_URL="https://wildfire.paloaltonetworks.com/publicapi/test/pe"
APK_URL="https://wildfire.paloaltonetworks.com/publicapi/test/apk"
MACOSX_URL="https://wildfire.paloaltonetworks.com/publicapi/test/macos"
ELF_URL="https://wildfire.paloaltonetworks.com/publicapi/test/elf"

# Download files
download_file "$PE_URL" "test_pe.exe"
download_file "$APK_URL" "test_apk.apk"
download_file "$MACOSX_URL" "test_macos.dmg"
download_file "$ELF_URL" "test_elf.elf"

# List downloaded files
echo "Listing downloaded files in $DOWNLOAD_DIR:"
ls -l "$DOWNLOAD_DIR"

# Make sure to clean up after (optional)
# Uncomment the line below if you want to delete the downloaded files after use
# rm -rf "$DOWNLOAD_DIR"
