#!/bin/bash

# File di log
LOG_FILE="/home/pi/install_log.txt"

# Funzione per la barra di avanzamento
progress_bar() {
    local progress=$1
    local total=$2
    local width=50
    local filled=$((progress * width / total))
    local empty=$((width - filled))
    local bar="["$(printf "%${filled}s" "=")$(printf "%${empty}s" " ")"]"
    echo -ne "\r$bar $((progress * 100 / total))%"
}

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

# Fase 2: Installazione di autofs, mpv e gpiozero
echo "Installazione di autofs, mpv e gpiozero..."
{
    sudo apt update
    sudo apt install autofs mpv python3-gpiozero -y
} &>> $LOG_FILE
progress_bar 1 10

# Fase 3: Configurazione del file /etc/auto.master
echo "Configurazione del file /etc/auto.master..."
{
    echo "/media/pi /etc/auto.usb --timeout=10" | sudo tee -a /etc/auto.master
} &>> $LOG_FILE
progress_bar 2 10

# Fase 4: Configurazione del file /etc/auto.usb
echo "Configurazione del file /etc/auto.usb..."
{
    if [ "$boot_usb" == "y" ]; then
        echo "USB -fstype=auto,defaults,nofail :/dev/sdb1" | sudo tee /etc/auto.usb
    else
        echo "USB -fstype=auto,defaults,nofail :/dev/sda1" | sudo tee /etc/auto.usb
    fi
} &>> $LOG_FILE
progress_bar 3 10

# Fase 5: Riavvio del servizio autofs
echo "Riavvio del servizio autofs..."
{
    sudo systemctl restart autofs
} &>> $LOG_FILE
progress_bar 4 10

# Fase 6: Copia degli script e del servizio
echo "Copia degli script e del servizio nelle posizioni corrette..."
{
    sudo cp ./device_added.sh /bin/device_added.sh
    sudo cp ./device_removed.sh /bin/device_removed.sh
    sudo cp ./video_control.py /home/pi/video_control.py
    sudo cp ./video_control.service /etc/systemd/system/video_control.service
} &>> $LOG_FILE
progress_bar 5 10

# Fase 7: Rendi eseguibili gli script
echo "Rendendo eseguibili gli script device_added.sh e device_removed.sh..."
{
    sudo chmod +x /bin/device_added.sh
    sudo chmod +x /bin/device_removed.sh
} &>> $LOG_FILE
progress_bar 6 10

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
progress_bar 7 10

# Fase 9: Ricarica udev
echo "Ricaricamento delle regole udev..."
{
    sudo udevadm control --reload
} &>> $LOG_FILE
progress_bar 8 10

# Fase 10: Rendi eseguibile lo script video_control.py
echo "Rendendo eseguibile il video_control.py..."
{
    sudo chmod +x /home/pi/video_control.py
} &>> $LOG_FILE
progress_bar 9 10

# Fase 11: Ricarica systemd, abilita e avvia il servizio
echo "Ricaricando systemd e avviando il servizio video_control..."
{
    sudo systemctl daemon-reload
    sudo systemctl enable video_control.service
    sudo systemctl start video_control.service
} &>> $LOG_FILE
progress_bar 10 10

# Fase 12: Richiesta di rimuovere la cartella "proiettore"
echo "Desideri rimuovere la cartella 'proiettore' (se presente)? (y/n)"
read -r remove_folder
echo "Scelta: $remove_folder" | tee -a $LOG_FILE

if [ "$remove_folder" == "y" ]; then
    echo "Rimuovendo la cartella 'proiettore'..." | tee -a $LOG_FILE
    sudo rm -rf /path/to/proiettore
    echo "Cartella 'proiettore' rimossa con successo." | tee -a $LOG_FILE
fi

# Fase 13: Richiesta di visualizzazione log e riavvio
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
