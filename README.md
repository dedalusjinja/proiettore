
# Proiettore Gabriele - Script di Installazione e Configurazione

Questo script è progettato per automatizzare l'installazione e la configurazione di un sistema per controllare un proiettore tramite un Raspberry Pi, utilizzando dispositivi USB per la gestione dei file di video. Esso include l'installazione di pacchetti necessari, la configurazione di autofs per il montaggio automatico dei dispositivi USB, la gestione dei dispositivi USB tramite regole udev, e il controllo dei video tramite GPIO.

## Funzionalità

- **Controllo dei Video**: Utilizza Python e mpv per il controllo dei video tramite GPIO.
- **Gestione Automatica dei Dispositivi USB**: Configura autofs per il montaggio automatico e gestisce l'inserimento e la rimozione dei dispositivi USB.
- **Servizio Systemd**: Esegue uno script di controllo video all'avvio del sistema tramite un servizio systemd.

## Installazione

### 1. Clonare il Repository

Per ottenere gli script necessari, inizia clonando il repository Git:

```bash
git clone https://github.com/dedalusjinja/proiettore.git
```

### 2. Esecuzione dello Script di Installazione

Una volta clonato il repository, naviga nella cartella del progetto ed esegui lo script di installazione:

```bash
cd /proiettore
chmod +x install.sh
./install.sh
```

Lo script di installazione eseguirà tutte le operazioni necessarie per configurare il sistema, inclusa la verifica della presenza di un disco di boot USB e la configurazione di autofs, udev, e il servizio systemd.

### 3. Funzione di Aggiornamento

Lo script supporta una funzionalità di aggiornamento che verifica se una versione precedente è già stata installata. In caso affermativo, chiederà se si desidera aggiornare. I file già presenti verranno rinominati con l'estensione `.old` prima che vengano copiati i nuovi file.

### 4. Permessi di Esecuzione

Dopo aver clonato il repository o copiato i file, verranno automaticamente assegnati i permessi di esecuzione agli script necessari. Non è necessario eseguire manualmente `chmod +x` per i file clonati o copiati.

## Funzionamento

Lo script configurerà il sistema con le seguenti fasi:

1. Verifica se il disco di boot è USB.
2. Installa pacchetti necessari (autofs, mpv, gpiozero).
3. Configura il file `/etc/auto.master` per il montaggio automatico dei dispositivi USB.
4. Configura il file `/etc/auto.usb` con la destinazione corretta in base alla configurazione del disco di boot.
5. Riavvia il servizio autofs.
6. Copia gli script e il servizio nelle posizioni corrette.
7. Rende eseguibili gli script `device_added.sh` e `device_removed.sh`.
8. Crea le regole udev per gestire l'inserimento e la rimozione dei dispositivi USB.
9. Ricarica il servizio udev.
10. Rende eseguibile lo script `video_control.py` e crea un servizio systemd per avviare il controllo dei video all'avvio.

### Aggiornamento

Se una versione precedente del sistema è già installata, lo script chiederà se si desidera eseguire l'aggiornamento. In tal caso, i file esistenti saranno rinominati con l'estensione `.old` prima di copiare i nuovi file.

## Log di Installazione

Durante l'esecuzione dello script, tutte le azioni vengono registrate nel file di log `install_log.txt` per una consultazione successiva. Alla fine dell'installazione, lo script chiederà se desideri visualizzare il log.

## Riavvio

Una volta completata l'installazione, lo script ti chiederà se desideri riavviare il sistema. Puoi scegliere di riavviare immediatamente o farlo manualmente in un secondo momento.

