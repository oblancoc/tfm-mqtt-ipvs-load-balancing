#!/usr/bin/bash

# 1. Recibe el nombre del experimento como argumento.
if [ -n "$1" ]; then
    EXPERIMENT_NAME="$1"
else
    # Fallback: si se ejecuta directamente, solicita el nombre.
    read -p "Fallback: Introduce el nombre para el monitoreo CSV: " EXPERIMENT_NAME
    if [ -z "$EXPERIMENT_NAME" ]; then
        echo "No se introdujo un nombre. Se usará 'default_csv_experiment'."
        EXPERIMENT_NAME="default_csv_experiment"
    fi
fi

# Archivo de salida para las métricas en formato CSV.
CSVFILE="monitor_brokers_${EXPERIMENT_NAME}.csv"

# Nombres de los contenedores de brokers a monitorear.
BROKERS=("mosquitto_broker1" "mosquitto_broker2" "mosquitto_broker3")

# Intervalo para la captura de datos en segundos.
INTERVAL_CSV=0.02

# Inicialización del archivo CSV con las cabeceras.
echo "Monitoreo CSV iniciado para '$EXPERIMENT_NAME'. Guardando datos en $CSVFILE..."
if [ ! -f "$CSVFILE" ]; then
    echo "Fecha y hora,Contenedor,CPU %,Memoria usada,Memoria total,Memoria %,Red Rx,Red Tx,Block Rx,Block Tx" > "$CSVFILE"
fi

# Bucle principal para la captura de estadísticas de Docker.
while true; do
    TIMESTAMP_CSV=$(date "+%Y-%m-%d %H:%M:%S.%3N")

    # Obtiene las estadísticas de los contenedores sin streaming y las formatea.
    docker stats --no-stream "${BROKERS[@]}" --format \
    "{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}}" | \
    awk -F, -v ts="$TIMESTAMP_CSV" '
    {
        # Limpieza y procesamiento de los campos de docker stats.
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        
        split($3, mem_parts, " / "); 
        gsub(/^[ \t]+|[ \t]+$/, "", mem_parts[1]); mem_used = mem_parts[1];
        gsub(/^[ \t]+|[ \t]+$/, "", mem_parts[2]); mem_total = mem_parts[2];

        split($5, net_parts, " / "); 
        gsub(/^[ \t]+|[ \t]+$/, "", net_parts[1]); net_rx = net_parts[1];
        gsub(/^[ \t]+|[ \t]+$/, "", net_parts[2]); net_tx = net_parts[2];

        split($6, blk_parts, " / "); 
        gsub(/^[ \t]+|[ \t]+$/, "", blk_parts[1]); blk_rx = blk_parts[1];
        gsub(/^[ \t]+|[ \t]+$/, "", blk_parts[2]); blk_tx = blk_parts[2];

        print ts","$1","$2","mem_used","mem_total","$4","net_rx","net_tx","blk_rx","blk_tx
    }' >> "$CSVFILE"

    # Descomentar la siguiente línea para introducir un intervalo fijo entre capturas.
    # El bucle se ejecuta a la máxima velocidad posible si está comentado.
    # sleep "$INTERVAL_CSV"
done