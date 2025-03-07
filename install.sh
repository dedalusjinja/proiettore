#!/bin/bash

# File di log
LOG_FILE="/home/pi/install_log.txt"

# Fase 1: Verifica se il disco di boot è USB
echo "È il disco di boot USB? (y/n)"
read -r boot_usb
echo "Scelta: $boot_usb" | tee -a $LOG_FILE

if [ "$boot_usb" == "y" ]; then
    echo "Disco di boot è USB. Configurazioni specifiche in corso..." | tee -a $LOG_FILE
    USB_DEVICE="/dev/sdb1"
else
    echo "Disco di boot non è USB. Configurazioni generiche in corso..." | tee -a $LOG_FILE
    USB_DEVICE="/dev/sda1"
fi

# Fase 2: Installazione dei pacchetti necessari
echo "Installazione di autofs, mpv, gpiozero e pacchetti per il supporto ai filesystem USB..."
{
    sudo apt update
    sudo apt install -y autofs mpv python3-gpiozero exfat-fuse exfat-utils ntfs-3g dosfstools e2fsprogs
} &>> $LOG_FILE

# Fase 3: Configurazione del file /etc/auto.master
echo "Configurazione del file /etc/auto.master..."
{
    if ! grep -q "/media/pi /etc/auto.usb --timeout=10" /etc/auto.master; then
        echo "/media/pi /etc/auto.usb --timeout=10" | sudo tee -a /etc/auto.master
    fi
} &>> $LOG_FILE

# Fase 4: Configurazione del file /etc/auto.usb
echo "Configurazione del file /etc/auto.usb..."
{
    if ! grep -q "USB -fstype=auto,defaults,nofail :$USB_DEVICE" /etc/auto.usb; then
        echo "USB -fstype=auto,defaults,nofail :$USB_DEVICE" | sudo tee /etc/auto.usb
    fi
} &>> $LOG_FILE

# Fase 5: Riavvio del servizio autofs
echo "Riavvio del servizio autofs..."
{
    sudo systemctl restart autofs
} &>> $LOG_FILE

# Fase 6: Copia degli script e del servizio
echo "Copia degli script e del servizio nelle posizioni corrette..."
{
    sudo cp ./device_added.sh /bin/device_added.sh
    sudo cp ./device_removed.sh /bin/device_removed.sh
    sudo cp ./video_control.py /home/pi/video_control.py
    sudo cp ./video_control.service /etc/systemd/system/video_control.service
} &>> $LOG_FILE

# Fase 7: Rendi eseguibili gli script
echo "Rendendo eseguibili gli script device_added.sh e device_removed.sh..."
{
    sudo chmod +x /bin/device_added.sh
    sudo chmod +x /bin/device_removed.sh
} &>> $LOG_FILE

# Fase 8: Creazione del file delle regole udev
echo "Creazione delle regole udev..."
{
    if [ "$boot_usb" == "y" ]; then
        sudo bash -c 'cat > /etc/udev/rules.d/80-test.rules <<EOF
SUBSYSTEM=="block", ENV{DEVNAME}=="/dev/sdb", ACTION=="add", RUN+="/bin/device_added.sh"
SUBSYSTEM=="block", ENV{DEVNAME}=="/dev/sdc", ACTION=="add", RUN+="/bin/device_added.sh"
SUBSYSTEM=="block", ENV{DEVNAME}=="/dev/sdb", ACTION=="remove", RUN+="/bin/device_removed.sh"
SUBSYSTEM=="block", ENV{DEVNAME}=="/dev/sdc", ACTION=="remove", RUN+="/bin/device_removed.sh"
EOF'
    else
        sudo bash -c 'cat > /etc/udev/rules.d/80-test.rules <<EOF
SUBSYSTEM=="usb", ACTION=="add", ENV{DEVTYPE}=="usb_device", RUN+="/bin/device_added.sh"
SUBSYSTEM=="usb", ACTION=="remove", ENV{DEVTYPE}=="usb_device", RUN+="/bin/device_removed.sh"
EOF'
    fi
} &>> $LOG_FILE

# Fase 9: Ricarica udev
echo "Ricaricamento delle regole udev..."
{
    sudo udevadm control --reload
} &>> $LOG_FILE

# Fase 10: Rendi eseguibile lo script video_control.py
echo "Rendendo eseguibile il video_control.py..."
{
    sudo chmod +x /home/pi/video_control.py
} &>> $LOG_FILE

# Fase 11: Ricarica systemd, abilita e avvia il servizio
echo "Ricaricando systemd e avviando il servizio video_control..."
{
    sudo systemctl daemon-reload
    sudo systemctl enable video_control.service
    sudo systemctl start video_control.service
} &>> $LOG_FILE

# Fase 12: Configurazione della console di avvio
echo "🔧 Configurazione della console di avvio..."
sudo sed -i 's/console=tty1/console=tty3/g' /boot/firmware/cmdline.txt

if ! grep -q "console=tty3 loglevel=0 quiet splash vt.global_cursor_default=0" /boot/firmware/cmdline.txt; then
    sudo sed -i 's/$/ console=tty3 loglevel=0 quiet splash vt.global_cursor_default=0/' /boot/firmware/cmdline.txt
fi

echo "✅ Configurazione della console completata: tty1 disabilitato, log spostati su tty3."

# Fase 13: Richiesta di cancellazione della cartella di download
echo "Desideri cancellare la cartella 'proiettore' in cui sono stati scaricati i file? (y/n)"
read -r delete_folder
echo "Scelta: $delete_folder" | tee -a $LOG_FILE

if [ "$delete_folder" == "y" ]; then
    echo "Cancellazione della cartella 'proiettore' in corso..." | tee -a $LOG_FILE
    rm -rf /home/pi/proiettore 
    echo "Cartella 'proiettore' cancellata." | tee -a $LOG_FILE
else
    echo "La cartella 'proiettore' non è stata cancellata." | tee -a $LOG_FILE
fi

# Fase 14: Richiesta di visualizzazione log e riavvio
echo "L'installazione è stata completata con successo!"
echo "Desideri visualizzare il log prima di riavviare? (y/n)"
read -r view_log
echo "Scelta: $view_log" | tee -a $LOG_FILE

if [ "$view_log" == "y" ]; then
    echo "Visualizzazione del log:"
    cat $LOG_FILE
fi

echo "Desideri riavviare il sistema ora? (y/n)"
read -r reboot_choice
echo "Scelta: $reboot_choice" | tee -a $LOG_FILE

if [ "$reboot_choice" == "y" ]; then
    echo "Riavvio in corso..." | tee -a $LOG_FILE
    sudo reboot
else
    echo "Puoi riavviare il sistema manualmente quando necessario." | tee -a $LOG_FILE
fi
