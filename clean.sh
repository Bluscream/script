#!/bin/bash

# Step 1: Remove unneeded packages
echo "Removing unneeded packages..."
sudo apt-get autoremove -y

# Step 2: Empty all .log files and delete common metadata files
echo "Emptying .log files and deleting common metadata files..."
sudo find / -type f \( -name "*.log" -o -name ".*DS_Store" -o -name ".*Thumbs.db" -o -name "desktop.ini" \) -exec sh -c 'if [ -f "$1" ]; then truncate -s 0 "$1"; else rm -f "$1"; fi' _ {} \;

# Step 3: Delete all .gz files in /var/log
echo "Deleting .gz files in /var/log..."
sudo find /var/log -type f -name "*.*.gz" -exec rm {} \;

# Additional steps to clear up space

# Step 4: Clear package cache
echo "Clearing package cache..."
sudo apt-get clean

# Step 5: Remove orphaned packages
echo "Removing orphaned packages..."
sudo deborphan | xargs sudo apt-get -y remove --purge

# Step 6: Remove old kernels
echo "Removing old kernels..."
sudo dpkg --purge $(sudo dpkg -l 'linux-*' | awk '/^ii/{ print $2}' | grep -v -e `uname -r | cut -f1,2 -d"-"` | grep -E 'image|headers')

# Step 7: Clean up thumbnail cache for each user and delete common metadata files
echo "Cleaning up thumbnail cache for each user and deleting common metadata files..."
sudo find /home -type d -name 'thumbnails' -exec rm -rf {} \;
sudo find / -type f \( -name ".*DS_Store" -o -name ".*thumbs" -o -name ".*Thumbs.db" -o -name "desktop.ini" \) -exec rm -f {} \;

# Step 8: Clean up temporary files
echo "Cleaning up temporary files..."
sudo rm -rf /tmp/*

# Step 9: Check for and remove any snap packages that are no longer in use
echo "Removing unused snap packages..."
sudo snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done

# Step 10: Check for and remove any unused Docker images, containers, and volumes
echo "Removing unused Docker resources..."
docker system prune -a -f

echo "Cleanup completed."
