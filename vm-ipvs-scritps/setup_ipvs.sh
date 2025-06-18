#!/bin/bash

echo "--- Script de Configuración de IPVS ---"

# 1. Limpiar configuración existente de IPVS.
echo "Limpiando todas las reglas y contadores previos..."
sudo ipvsadm -C
echo ""

# 2. Seleccionar y cargar nuevo conjunto de reglas.
read -r -p "Selecciona el algoritmo de balanceo a cargar [LC/RR]: " choice
choice_upper=$(echo "$choice" | tr '[:lower:]' '[:upper:]') # Convertir a mayúsculas para la comparación.

case "$choice_upper" in
    "LC")
        if [ -f "/etc/ipvs_lc.rules" ]; then
            echo "Cargando configuración 'Least Connections' (LC)..."
            sudo ipvsadm-restore < /etc/ipvs_lc.rules
        else
            echo "Error: Archivo /etc/ipvs_lc.rules no encontrado."
            exit 1
        fi
        ;;
    "RR")
        if [ -f "/etc/ipvs_rr.rules" ]; then
            echo "Cargando configuración 'Round Robin' (RR)..."
            sudo ipvsadm-restore < /etc/ipvs_rr.rules
        else
            echo "Error: Archivo /etc/ipvs_rr.rules no encontrado."
            exit 1
        fi
        ;;
    *)
        echo "Opción no válida. No se cargaron reglas."
        exit 1
        ;;
esac

# 3. Mostrar el estado final de la configuración.
echo ""
echo "Configuración cargada exitosamente. Estado actual de IPVS:"
sudo ipvsadm -L -n

exit 0