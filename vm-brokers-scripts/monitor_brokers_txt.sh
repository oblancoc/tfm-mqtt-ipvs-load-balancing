#!/usr/bin/bash

# 1. Recibe el nombre del experimento como argumento.
if [ -n "$1" ]; then
    EXPERIMENT_NAME="$1"
else
    # Fallback: si se ejecuta directamente, solicita el nombre.
    read -p "Fallback: Introduce el nombre para el monitoreo de logs TXT: " EXPERIMENT_NAME
    if [ -z "$EXPERIMENT_NAME" ]; then
        echo "No se introdujo un nombre. Se usará 'default_txt_experiment'."
        EXPERIMENT_NAME="default_txt_experiment"
    fi
fi

# Archivo de salida para los logs detallados.
LOGFILE="monitor_brokers_${EXPERIMENT_NAME}.txt"

# Nombres de los contenedores de brokers a monitorear.
BROKERS=("mosquitto_broker1" "mosquitto_broker2" "mosquitto_broker3")

# Intervalo para la ejecución de netstat y la captura de logs.
INTERVAL_NET_LOG=1

# Intervalo del bucle principal del script.
INTERNAL_LOOP_SLEEP=0.5

echo "Monitoreo de Netstat y Docker Logs iniciado para '$EXPERIMENT_NAME'. Guardando datos en $LOGFILE..."
echo "Recolectando datos cada $INTERVAL_NET_LOG segundos."

last_net_log_time=$(($(date +%s) - INTERVAL_NET_LOG))

while true; do
    CURRENT_SECONDS_EPOCH=$(date +%s)

    if (( CURRENT_SECONDS_EPOCH - last_net_log_time >= INTERVAL_NET_LOG )); then
        # Utiliza un timestamp con milisegundos para mayor precisión en los logs.
        TIMESTAMP_LOG=$(date "+%Y-%m-%d %H:%M:%S.%3N")
        echo "--- Bloque Netstat/DockerLogs @ $TIMESTAMP_LOG ---" >> "$LOGFILE"
        
        for BROKER_NAME in "${BROKERS[@]}"; do
            echo "--- [$TIMESTAMP_LOG] netstat para $BROKER_NAME ---" >> "$LOGFILE"
            docker exec "$BROKER_NAME" netstat -ant | grep 1883 >> "$LOGFILE" 2>/dev/null

            echo "--- [$TIMESTAMP_LOG] últimos logs (10 líneas) para $BROKER_NAME ---" >> "$LOGFILE"
            docker logs --tail 10 "$BROKER_NAME" >> "$LOGFILE" 2>&1
        done
        
        echo "-----------------------------------------------------" >> "$LOGFILE"
        last_net_log_time=$CURRENT_SECONDS_EPOCH
    fi

    sleep "$INTERNAL_LOOP_SLEEP"
done