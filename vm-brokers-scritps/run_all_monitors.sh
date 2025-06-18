#!/bin/bash

# Define los scripts de monitoreo a ejecutar.
SCRIPT_CSV="./monitor_brokers_csv.sh"
SCRIPT_TXT_LOG="./monitor_brokers_txt.sh"

# 1. Solicita un nombre base para identificar los archivos de este experimento.
read -p "Introduce el nombre base para este experimento (ej: Escenario0_Prueba1): " GLOBAL_EXPERIMENT_NAME

# Valida que se haya introducido un nombre.
if [ -z "$GLOBAL_EXPERIMENT_NAME" ]; then
  echo "No se introdujo un nombre para el experimento. Abortando."
  exit 1
fi

# Verifica que los scripts de monitoreo existen y son ejecutables.
echo "Verificando scripts de monitoreo..."
if [ ! -f "$SCRIPT_CSV" ] || [ ! -x "$SCRIPT_CSV" ]; then
    echo "Error: $SCRIPT_CSV no encontrado o no es ejecutable."
    exit 1
fi
if [ ! -f "$SCRIPT_TXT_LOG" ] || [ ! -x "$SCRIPT_TXT_LOG" ]; then
    echo "Error: $SCRIPT_TXT_LOG no encontrado o no es ejecutable."
    exit 1
fi

# Lanza los scripts de monitoreo en segundo plano.
echo "Lanzando monitores para el experimento: ${GLOBAL_EXPERIMENT_NAME}..."

$SCRIPT_CSV "${GLOBAL_EXPERIMENT_NAME}" &
CSV_PID=$!
echo "PID del script CSV: $CSV_PID"

$SCRIPT_TXT_LOG "${GLOBAL_EXPERIMENT_NAME}" &
LOG_PID=$!
echo "PID del script TXT Log: $LOG_PID"

# Función de limpieza que se ejecuta al recibir una señal de interrupción (Ctrl+C).
cleanup() {
    echo ""
    echo "Recibida señal de interrupción. Deteniendo scripts de monitoreo..."
    # Intenta una detención normal primero.
    kill $CSV_PID $LOG_PID 2>/dev/null
    sleep 0.5
    # Forzar la detención de los scripts que no respondieron a la señal inicial.
    if ps -p $CSV_PID > /dev/null; then
       echo "Forzando detención de script CSV (PID: $CSV_PID)..."
       kill -9 $CSV_PID 2>/dev/null
    fi
    if ps -p $LOG_PID > /dev/null; then
       echo "Forzando detención de script TXT Log (PID: $LOG_PID)..."
       kill -9 $LOG_PID 2>/dev/null
    fi
    echo "Scripts de monitoreo detenidos."
    exit 0
}

# Captura las señales SIGINT (Ctrl+C) y SIGTERM para ejecutar la función de limpieza.
trap cleanup SIGINT SIGTERM

echo ""
echo "Ambos scripts de monitoreo están corriendo en paralelo."
echo "Presiona Ctrl+C en esta terminal para detenerlos."
echo ""

# Espera a que los procesos terminen.
wait $CSV_PID
PID1_EXIT_STATUS=$?
wait $LOG_PID
PID2_EXIT_STATUS=$?

# Este bloque se alcanza si los scripts terminan por sí mismos de forma inesperada.
echo "Uno o ambos scripts han terminado."
echo "Estado de salida de $SCRIPT_CSV: $PID1_EXIT_STATUS"
echo "Estado de salida de $SCRIPT_TXT_LOG: $PID2_EXIT_STATUS"
cleanup # Llama a cleanup para asegurar que ambos procesos se detengan.