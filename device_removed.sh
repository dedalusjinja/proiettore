#!/bin/bash
echo "USB device removed at \$(date)" >> /home/pi/scripts.log
echo -e "\033c" > /dev/tty2
sudo chvt 1