# Detect if the Overlay File System is active or not
    DIRECTORY="/media/root-ro"
    if [ -d "$DIRECTORY" ]; then
        echo -e "The Overlay File System is active.\n Temporary remouting '/media/root-ro' as Read/Write"

        # Remounting /media/root-ro as Read/Write
        sudo mount -o remount,rw /media/root-ro
        #mount -v | grep /media/root-ro

        # Make the required adjustments in  the config.txt file
        sudo nano /media/root-ro/opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt

        # Remounting /media/root-ro as Read Only again.
        sudo mount -o remount,ro /media/root-ro
        #mount -v | grep /media/root-ro
        if mount -v | grep -q "/dev/mmcblk0p2 on /media/root-ro type ext4 (ro,relatime)";then
            echo "Remounted '/media/root-ro' as Read Only again."
        else
            echo "!!!Remount to Read Only failed!!!"
            echo "Reboot the device using   sudo reboot   to fully activate the Overlay File System again and then check the config."
        fi

    else
        echo "The Overlay File System is not active."

        # Make the required adjustments in  the config.txt file
        sudo nano /opt/st/stm32cubeclt_1.18.0/STLink-gdb-server/bin/config.txt
    fi

# Ask the user for confirmation
echo ""
read -n 1 -p "Do you want to restart the 'ST-Link GDB Server' service to make the new settings active? [Y/n]: " response #-n 1 → Reads only one character.

# If user presses Enter without input, set response to "yes"
response=${response:-yes}

# Convert response to lowercase for consistency
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

# Check response (accept "yes", "y", or default)
if [[ "$response" == "yes"  || "$response" == "y" ]]; then
    echo "Restarting the 'ST-Link GDB Server' service..."
    sudo systemctl restart stlink-gdb-server.service
    echo "'ST-Link GDB Server' service restarted successfully."
else
    # The -e option in the echo command enables interpretation of escape sequences like \n for new lines, \t for tabs, and more.
    echo -e "\n'ST-Link GDB Server' service restart canceled. \n\n!!!Changes made in the config.txt file are not active!!! \n\nTo get the changes active either: \n\t-Reboot the device using \n\t\tsudo reboot \n\t-Restart the 'ST-Link GDB Server' service using \n\t\tsudo systemctl restart stlink-gdb-server.service"
fi
