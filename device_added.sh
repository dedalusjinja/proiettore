#!/bin/bash
sleep 2
echo "USB device added at $(date)" >> /home/pi/scripts.log
DEVICE_NAME="${DEVNAME}"
if [[ -z "$DEVICE_NAME" ]]; then
    echo "Errore: variabile DEVNAME non impostata. Esco..." 
    exit 1
fi
echo "Dispositivo rilevato: $DEVICE_NAME"
sudo chvt 2
exec > /dev/tty2 2>&1
if mount | grep "$DEVICE_NAME" > /dev/null; then
    MOUNT_POINT=$(mount | grep "$DEVICE_NAME" | awk '{print $3}')
    if [[ -z "$MOUNT_POINT" ]]; then
        echo "Errore: impossibile determinare il punto di mount!" 
        exit 1
    fi
    FILE_ONE="$MOUNT_POINT/uno.mp4"
    FILE_TWO="$MOUNT_POINT/due.mp4"
    if [ -f "$FILE_ONE" ] && [ -f "$FILE_TWO" ]; then
        cp -f "$FILE_ONE" /home/pi/ 2>/dev/null
        cp -f "$FILE_TWO" /home/pi/ 2>/dev/null
        touch /home/pi/copy_complete.txt
    else
        echo "File mp4 non trovati!"
    fi
else
    echo "Dispositivo non montato correttamente!"
fi