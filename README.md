
# Raspberry Pi Setup and Configuration

Questo repository contiene gli script necessari per configurare un Raspberry Pi con supporto per il montaggio automatico dei dispositivi USB, controllo video tramite GPIO, e avvio di un servizio video al boot. Gli script sono progettati per automatizzare l'installazione e la configurazione di vari pacchetti e servizi.

## Struttura dei File

### `install.sh`
Questo è lo script principale di installazione. Esso:
1. Verifica se il disco di boot è USB.
2. Installa i pacchetti necessari: `autofs`, `mpv`, e `python3-gpiozero`.
3. Configura il file `/etc/auto.master` per il montaggio dei dispositivi USB.
4. Configura il file `/etc/auto.usb` per il montaggio automatico dei dispositivi USB.
5. Copia gli script e il servizio nel sistema.
6. Rende eseguibili gli script `device_added.sh` e `device_removed.sh`.
7. Configura le regole `udev` per gestire l'aggiunta e la rimozione dei dispositivi USB.
8. Ricarica e avvia i servizi necessari, tra cui `video_control.service`.
9. Configura il sistema per non mostrare il cursore lampeggiante su `tty1` e spostare i log su `tty3`.

### `device_added.sh`
Questo script viene eseguito quando un dispositivo USB viene aggiunto. Le sue operazioni includono:
1. Registrare l'aggiunta del dispositivo in un file di log.
2. Verificare se i file `uno.mp4` e `due.mp4` sono presenti sul dispositivo USB.
3. Copiare questi file nella home directory di `pi` e creare un file di stato `copy_complete.txt`.
4. Cambiare il terminale su `tty2` per visualizzare eventuali log e messaggi.

### `device_removed.sh`
Questo script viene eseguito quando un dispositivo USB viene rimosso. Le sue operazioni includono:
1. Registrare la rimozione del dispositivo in un file di log.
2. Ripristinare la visualizzazione su `tty1` e pulire il terminale `tty2`.

### `video_control.py`
Questo script Python gestisce il controllo video tramite GPIO. È progettato per:
1. Gestire l'avvio e il controllo della riproduzione di video (incluso il controllo di `mpv`).
2. Gestire il lampeggio di un LED in relazione al completamento di un'operazione di copia.
3. Gestire il riavvio e lo spegnimento del Raspberry Pi tramite pulsanti.

### `video_control.service`
Questo file `systemd` è utilizzato per eseguire lo script `video_control.py` come servizio al boot. La configurazione include:
1. Avvio del servizio all'avvio del sistema.
2. Monitoraggio continuo del servizio con riavvio automatico in caso di fallimento.

## Come Usare

1. **Clonare il repository:**
   ```bash
   git clone https://github.com/dedalusjinja/proiettore
   cd proiettore
   ```

2. **Eseguire lo script di installazione:**
   Prima di eseguire lo script, rendilo eseguibile:
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```

3. **Configurazione e avvio:**
   Dopo aver completato l'installazione, lo script `install.sh` configurerà tutto il necessario, inclusi il montaggio automatico dei dispositivi USB, la configurazione di GPIO per il controllo video, e l'avvio del servizio `video_control`.

4. **Rendere eseguibili gli script:**
   Gli script `device_added.sh` e `device_removed.sh` verranno automaticamente resi eseguibili dallo script di installazione. Non è necessaria alcuna operazione manuale.

5. **Riavvio del sistema:**
   Dopo aver completato l'installazione, puoi riavviare il sistema:
   ```bash
   sudo reboot
   ```

## Licenza
Questo progetto è sotto licenza MIT. Vedi il file LICENSE per maggiori dettagli.
