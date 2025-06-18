#!/bin/bash

DEFAULT_QOS=1

echo "--- Configuración del Experimento de Suscriptores MQTT ---"

# Solicita los parámetros para la prueba de carga.
read -r -p "Introduce el identificador para este experimento (ej: 1, expA): " exp_num
read -r -p "Introduce la IP del Host/VIP de destino (ej: 10.3.0.10): " host_ip
read -r -p "Introduce el número de clientes suscriptores (ej: 100): " num_clients
read -r -p "Introduce el QoS (0, 1, 2) [Default: $DEFAULT_QOS]: " qos_val

# Validación de entradas.
if [[ -z "$host_ip" ]] || ! [[ "$num_clients" =~ ^[0-9]+$ ]] || [[ "$num_clients" -le 0 ]] || \
   ! [[ "${qos_val:-$DEFAULT_QOS}" =~ ^[0-2]$ ]]; then
    echo "Error: Uno o más parámetros son inválidos."
    exit 1
fi

# Asigna valores por defecto si el usuario no los introdujo.
qos_val=${qos_val:-$DEFAULT_QOS}

# Define los archivos de salida para los logs.
output_dir="/home/azureuser"
mkdir -p "$output_dir"
command_logfile="${output_dir}/ipvs_sub_command_exp${exp_num}.txt"
metrics_logfile="${output_dir}/ipvs_sub_metrics_exp${exp_num}.txt"

# Construye el comando de emqtt-bench.
base_command="docker run --rm --network=host emqtt-bench sub"
params="-h ${host_ip} -p 1883 -c ${num_clients} -t bench/test -q ${qos_val}"
full_command="${base_command} ${params}"

# Guarda un registro del comando y sus parámetros.
{
    echo "Comando ejecutado:"
    echo "${full_command} | tee ${metrics_logfile}"
    echo ""
    echo "Parámetros:"
    echo "  Experimento: $exp_num"
    echo "  Host (-h): $host_ip"
    echo "  Clientes (-c): $num_clients"
    echo "  QoS (-q): $qos_val"
} > "$command_logfile"

echo ""
echo "Comando que se ejecutará:"
echo "${full_command} | tee ${metrics_logfile}"
echo ""
read -r -p "¿Lanzar el experimento? [S/n]: " confirm

if [[ "${confirm^^}" == "S" ]] || [[ -z "$confirm" ]]; then
    echo "Lanzando experimento de suscriptores..."
    eval "${full_command} | tee ${metrics_logfile}"
    echo "Experimento finalizado. Métricas guardadas en: ${metrics_logfile}"
else
    echo "Experimento cancelado."
fi

exit 0