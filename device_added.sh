
#!/bin/bash

# Pausa di 2 secondi all'inizio dello script
sleep 2

echo "USB device added at $(date)" >> /home/pi/scripts.log

# Cambiare il terminale di uscita (TTY)
sudo chvt 2  # Cambia il terminale su TTY2
echo "Attivando TTY2 su HDMI..."

# Verifica la presenza dei file mp4 nella destinazione
FILE_ONE="/media/pi/USB/uno.mp4"
FILE_TWO="/media/pi/USB/due.mp4"

if [ -f "$FILE_ONE" ] && [ -f "$FILE_TWO" ]; then
    echo "File trovati: $FILE_ONE e $FILE_TWO. Copia in corso..."

    # Copiare i file nella home senza mostrare gli errori
    cp -f "$FILE_ONE" /home/pi/ 2>/dev/null
    cp -f "$FILE_TWO" /home/pi/ 2>/dev/null

    # Verifica se i file sono stati copiati con successo
    if [ -f "/home/pi/uno.mp4" ] && [ -f "/home/pi/due.mp4" ]; then
        echo "File copiati con successo!"

        # Creare il file di stato per segnare la fine della copia
        touch /home/pi/copy_complete.txt
        echo "Segnalazione completamento copia (file di stato creato)."
    else
        echo "Errore nella copia dei file."
    fi
else
    echo "File mp4 non trovati: uno.mp4 e due.mp4 non presenti nella chiavetta"
fi

# Scrivere il messaggio finale
echo "Ora estrarre la chiavetta per tornare allo schermo nero."
