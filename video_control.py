import os
import time
from subprocess import Popen, DEVNULL
from gpiozero import Button, LED
import RPi.GPIO as GPIO  # Importa il modulo per la pulizia GPIO

# Percorsi dei video da riprodurre
movie1 = "/home/pi/uno.mp4"
movie2 = "/home/pi/due.mp4"
movie3 = "/home/pi/tre.mp4"
movie4 = "/home/pi/quattro.mp4"

# LED per indicare lo stato
led = LED(23)

# Variabile globale per il player
player = None

# Funzione per loggare lo stato
def log_status(message):
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    print(f"{timestamp} - {message} 📽️")  # Stampa nel terminale con emoji

# Funzione per fermare il player se un video è in esecuzione
def stop_player():
    global player
    if player:
        log_status("Fermando la riproduzione del video 🛑")
        player.terminate()  # Termina il processo del player
        player.wait()  # Aspetta che il processo finisca
        player = None  # Resetta la variabile player

# Funzione per spegnere il Raspberry Pi
def shutdown_raspberry():
    log_status("Spegnimento del Raspberry Pi in corso 🔌💤")
    os.system("sudo shutdown now")  # Esegue il comando di spegnimento

# Funzione per riavviare il Raspberry Pi
def reboot_raspberry():
    log_status("Riavvio del Raspberry Pi in corso 🔄")
    os.system("sudo reboot")  # Esegue il comando di riavvio

# Funzione per lampeggiare il LED per 4 secondi
def blink_led(duration):
    start_time = time.time()
    while time.time() - start_time < duration:
        led.on()
        time.sleep(0.5)  # Pausa di mezzo secondo
        led.off()
        time.sleep(0.5)

# Funzione per controllare la presenza del file di stato (copia completata)
def check_copy_complete():
    return os.path.exists('/home/pi/copy_complete.txt')

# Funzione per riprodurre un video
def play_video(movie_path):
    stop_player()  # Ferma il video corrente, se presente
    log_status(f"Riproduzione di {movie_path} in corso 🎥")
    global player
    player = Popen(["sudo", "-u", "pi", "bash", "-c", f"mpv --fullscreen --quiet --no-config --log-file=/tmp/mpv_log.txt {movie_path}"], stdout=DEVNULL, stderr=DEVNULL)

# Impostazione dei pulsanti
button_video1 = Button(17, bounce_time=0.3)  # Pulsante per video 1
button_video2 = Button(18, bounce_time=0.3)  # Pulsante per video 2
button_video3 = Button(27, bounce_time=0.3)  # Pulsante per video 3
button_video4 = Button(22, bounce_time=0.3)  # Pulsante per video 4
button_stop = Button(24, bounce_time=0.3)    # Pulsante per fermare video
button_shutdown = Button(26, bounce_time=0.3)  # Pulsante per spegnere Raspberry Pi
button_reboot = Button(19, bounce_time=0.3)   # Pulsante per riavviare Raspberry Pi

# Associare i pulsanti agli eventi
button_video1.when_pressed = lambda: play_video(movie1)
button_video2.when_pressed = lambda: play_video(movie2)
button_video3.when_pressed = lambda: play_video(movie3)
button_video4.when_pressed = lambda: play_video(movie4)
button_stop.when_pressed = stop_player
button_shutdown.when_pressed = shutdown_raspberry
button_reboot.when_pressed = reboot_raspberry

# Accendi il LED all'inizio
led.on()

# Loop principale
try:
    while True:
        # Se il file di stato esiste (copia completata), lampeggia il LED
        if check_copy_complete():
            blink_led(4)  # Lampeggia per 4 secondi
            led.on()
            os.remove('/home/pi/copy_complete.txt')  # Rimuove il file di stato

        time.sleep(0.1)  # Pausa breve per ridurre il carico sulla CPU

except KeyboardInterrupt:
    print("Programma interrotto dall'utente")

finally:
    # Pulizia dei pin GPIO alla fine del programma
    GPIO.cleanup()
    log_status("Pulizia GPIO eseguita ✔️")

