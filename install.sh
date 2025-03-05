#!/bin/bash

# Mostra il logo con la stella cometa e la scritta "Proiettore Gabriele"
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

# Pausa per visualizzare il logo
sleep 2

# Funzione di aggiornamento
function aggiorna_installazione {
    echo "Controllo se l'installazione è già presente..."

    # Controlliamo se i file esistono
    if [ -f "/bin/device_added.sh" ] || [ -f "/bin/device_removed.sh" ] || [ -f "/home/pi/video_control.py" ] || [ -f "/etc/systemd/system/video_control.service" ]; then
        echo "I file di installazione sono già presenti."

        # Chiediamo all'utente se desidera aggiornare
        echo "Desideri aggiornare l'installazione? (y/n)"
        read -r risposta_aggiornamento
        if [ "$risposta_aggiornamento" == "y" ]; then
            echo "Rinomino i file esistenti con l'estensione .old..."

            # Rinomina i file esistenti
            mv /bin/device_added.sh /bin/device_added.sh.old
            mv /bin/device_removed.sh /bin/device_removed.sh.old
            mv /home/pi/video_control.py /home/pi/video_control.py.old
            mv /etc/systemd/system/video_control.service /etc/systemd/system/video_control.service.old

            echo "I file sono stati rinominati e saranno aggiornati con i nuovi file."
        else
            echo "Non verranno effettuati aggiornamenti."
            return
        fi
    else
        echo "Nessuna installazione precedente trovata. Procedo con una nuova installazione..."
    fi
}

# Esegui la funzione di aggiornamento all'inizio dello script
aggiorna_installazione

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
