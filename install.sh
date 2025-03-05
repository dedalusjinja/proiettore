#!/bin/bash

# Funzione per mostrare il logo
show_logo() {
    clear
    echo "__________________________________$$$"
    echo "_______________________________$$$$$"
    echo "____________________________$$$$$$"
    echo "__________________________$$$$$$$"
    echo "________________________$$$$$$$_$$$$$$$$$$$"
    echo "______________________$$$$$$$$$$$$$$$$$$"
    echo "____________________$$$$$$$$$$$$$$$"
    echo "___________________$$$$$$$$$$$$$"
    echo "_________________$$$$$$$$$$$$"
    echo "________________$$$$$$$$$$"
    echo "_______________$$$$$$$$$"
    echo "______________$$$$$$$$"
    echo "_____________$$$$$$$$"
    echo "____________$$$$$$$"
    echo "___________$$$$$$$"
    echo "___________$$$$$$"
    echo "__________$$$$$$"
    echo "__________$$$$$"
    echo "_________$$$$$"
    echo "_________$$$$"
    echo "________$$$$"
    echo "________$$$$"
    echo "________$$$"
    echo "________$$$_____$$"
    echo "__$______$$___$$"
    echo "____$$$$$$$$$$$$"
    echo "_____$$$$$$$$$$"
    echo "______$$$$$$$$$"
    echo "_____$$$$$$$$$$$$"
    echo "____$$$$$$$$$$$$$$$"
    echo "____$$$$$$$$$$$____$"
    echo "__$_____$$$$"
    echo "_________$$$"
    echo "__________$"
    echo ""
    echo "===================================="
    echo "        Proiettore Gabriele"
    echo "===================================="
    echo ""
}

# Funzione per chiedere l'aggiornamento e rinominare i file esistenti
ask_for_update() {
    echo "Vuoi aggiornare i file esistenti? (y/n)"
    read -r update_choice
    if [ "$update_choice" == "y" ]; then
        echo "Aggiornamento in corso..."
        
        # Rinomina i file esistenti con estensione .old
        if [ -f /bin/device_added.sh ]; then
            sudo mv /bin/device_added.sh /bin/device_added.sh.old
        fi
        if [ -f /bin/device_removed.sh ]; then
            sudo mv /bin/device_removed.sh /bin/device_removed.sh.old
        fi
        if [ -f /home/pi/video_control.py ]; then
            sudo mv /home/pi/video_control.py /home/pi/video_control.py.old
        fi
        if [ -f /etc/systemd/system/video_control.service ]; then
            sudo mv /etc/systemd/system/video_control.service /etc/systemd/system/video_control.service.old
        fi
        if [ -f /etc/udev/rules.d/80-test.rules ]; then
            sudo mv /etc/udev/rules.d/80-test.rules /etc/udev/rules.d/80-test.rules.old
        fi
    fi
}

# Mostra il logo
show_logo

# Verifica se è stato già installato
if [ -f /bin/device_added.sh ]; then
    echo "I file sono già stati installati. Vuoi aggiornare i file? (y/n)"
    read -r update_existing
    if [ "$update_existing" == "y" ]; then
        ask_for_update
    fi
else
    echo "Installazione iniziale in corso..."
fi

# Fase 2: Installazione di autofs, mpv e gpiozero
echo "Installazione di autofs, mpv e gpiozero..."
{
    sudo apt update
    sudo apt install autofs mpv python3-gpiozero -y
} &>> $LOG_FILE

# Fase 3: Configurazione del file /etc/auto.master
echo "Configurazione del file /etc/auto.master..."
{
    echo "/media/pi /etc/auto.usb --timeout=10" | sudo tee -a /etc/auto.master
} &>> $LOG_FILE

# Fase 4: Configurazione del file /etc/auto.usb
echo "Configurazione del file /etc/auto.usb..."
{
    if [ "$boot_usb" == "y" ]; then
        echo "USB -fstype=auto,defaults,nofail :/dev/sdb1" | sudo tee /etc/auto.usb
    else
        echo "USB -fstype=auto,defaults,nofail :/dev/sda1" | sudo tee /etc/auto.usb
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

# Fase 12: Richiesta di visualizzazione log e riavvio
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
