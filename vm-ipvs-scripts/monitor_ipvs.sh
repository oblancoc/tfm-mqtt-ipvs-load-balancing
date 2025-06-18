#!/bin/bash

# -----------------------------------------------------------------------------
# Sección 1: Configuración Inicial de IPVS
# -----------------------------------------------------------------------------
echo "--- Configuración Inicial de IPVS ---"

echo "Limpiando todas las reglas y contadores existentes..."
sudo ipvsadm -C
echo ""

read -r -p "Selecciona el algoritmo de balanceo a cargar [LC/RR]: " choice
choice_upper=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

if [[ "$choice_upper" == "LC" ]]; then
    if [ -f "/etc/ipvs_lc.rules" ]; then
        echo "Cargando configuración 'Least Connections' (LC) desde /etc/ipvs_lc.rules..."
        sudo ipvsadm-restore < /etc/ipvs_lc.rules
        echo "Configuración LC cargada."
    else
        echo "Error: Archivo de reglas /etc/ipvs_lc.rules no encontrado."
        exit 1
    fi
elif [[ "$choice_upper" == "RR" ]]; then
    if [ -f "/etc/ipvs_rr.rules" ]; then
        echo "Cargando configuración 'Round Robin' (RR) desde /etc/ipvs_rr.rules..."
        sudo ipvsadm-restore < /etc/ipvs_rr.rules
        echo "Configuración RR cargada."
    else
        echo "Error: Archivo de reglas /etc/ipvs_rr.rules no encontrado."
        exit 1
    fi
else
    echo "Opción no válida. No se cargaron reglas."
    exit 1
fi

echo ""
echo "Estado de IPVS después de la configuración:"
sudo ipvsadm -L -n --stats
echo "--- Fin de la Configuración ---"
echo ""

# -----------------------------------------------------------------------------
# Sección 2: Monitoreo Continuo de IPVS
# -----------------------------------------------------------------------------
read -p "Introduce el nombre para este monitoreo IPVS (ej: escenario1_ipvs): " EXPERIMENT_NAME

if [ -z "$EXPERIMENT_NAME" ]; then
  echo "Nombre no introducido. Se usará 'default_ipvs_experiment'."
  EXPERIMENT_NAME="default_ipvs_experiment"
fi

# Definición de archivos de salida.
LOGFILE_IPVS="monitor_ipvs_${EXPERIMENT_NAME}.txt"
CSVFILE_IPVS_STATS="monitor_ipvs_stats_${EXPERIMENT_NAME}.csv"
CSVFILE_IPVS_CONNS="monitor_ipvs_conns_${EXPERIMENT_NAME}.csv"

# Intervalo de captura en segundos.
INTERVAL=0.4

echo "Monitoreo IPVS iniciado. Guardando datos en los archivos con prefijo 'monitor_ipvs_*'..."
echo "Puedes detener el monitoreo con CTRL+C."

# Creación de encabezados para los archivos CSV si no existen.
if [ ! -f "$CSVFILE_IPVS_STATS" ]; then
    echo "Fecha y hora,ServicioVirtual,RealServer,ConexionesTotales,PaquetesEntrantes,PaquetesSalientes,BytesEntrantes,BytesSalientes" > "$CSVFILE_IPVS_STATS"
fi

if [ ! -f "$CSVFILE_IPVS_CONNS" ]; then
    echo "Fecha y hora,ServicioVirtual,RealServer,ConexionesActivas,ConexionesInactivas" > "$CSVFILE_IPVS_CONNS"
fi

# Captura la interrupción (CTRL+C) para una salida controlada.
trap 'echo ""; echo "Monitoreo IPVS detenido."; exit 0' SIGINT SIGTERM

while true; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S.%3N")

    # Vuelca las estadísticas y el estado de IPVS al archivo de log principal.
    echo "[$TIMESTAMP] Estado y Estadísticas de IPVS" >> "$LOGFILE_IPVS"
    sudo ipvsadm -L -n --stats >> "$LOGFILE_IPVS" 2>&1

    # Extrae las estadísticas de conexiones, paquetes y bytes a un CSV.
    sudo ipvsadm -L -n --stats | awk -v ts="$TIMESTAMP" '
    BEGIN { OFS="," }
    /^(TCP|UDP|SCTP)/ { virtual_service_ip_port = $2 }
    /^[ ]+->/ {
        print ts, virtual_service_ip_port, $2, $3, $4, $5, $6, $7
    }' >> "$CSVFILE_IPVS_STATS"

    # Extrae las conexiones activas e inactivas a un CSV separado.
    sudo ipvsadm -L -n | awk -v ts="$TIMESTAMP" '
    BEGIN { OFS="," }
    /^(TCP|UDP|SCTP)/ { virtual_service_ip_port = $2 }
    /^[ ]+->/ {
        print ts, virtual_service_ip_port, $2, $5, $6
    }' >> "$CSVFILE_IPVS_CONNS"

    # Captura información adicional de la red a intervalos menos frecuentes.
    if (( $(date +%s) % 5 == 0 )); then
        echo "[$TIMESTAMP] Resumen Conntrack y Conexiones TCP" >> "$LOGFILE_IPVS"
        sudo conntrack -C >> "$LOGFILE_IPVS" 2>&1
        netstat -antp | grep 1883 >> "$LOGFILE_IPVS" 2>&1
    fi

    echo "---------------------------------------------" >> "$LOGFILE_IPVS"
    sleep "$INTERVAL"
done