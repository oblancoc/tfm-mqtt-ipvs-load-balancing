#!/bin/bash

DEFAULT_QOS=1
DEFAULT_INTERVAL=500
DEFAULT_LIMIT=1000

echo "--- Configuración del Experimento de Publicadores MQTT ---"

# Solicita los parámetros para la prueba de carga.
read -r -p "Introduce el identificador para este experimento (ej: 1, expA): " exp_num
read -r -p "Introduce la IP del Host/VIP de destino (ej: 10.3.0.10): " host_ip
read -r -p "Introduce el número de clientes publicadores (ej: 100): " num_clients
read -r -p "Introduce el QoS (0, 1, 2) [Default: $DEFAULT_QOS]: " qos_val
read -r -p "Introduce el intervalo de publicación en ms (ej: 500) [Default: $DEFAULT_INTERVAL]: " interval_val
read -r -p "Introduce el límite de mensajes por publicador (ej: 1000) [Default: $DEFAULT_LIMIT]: " limit_val

# Validación de entradas.
if [[ -z "$host_ip" ]] || ! [[ "$num_clients" =~ ^[0-9]+$ ]] || [[ "$num_clients" -le 0 ]] || \
   ! [[ "${qos_val:-$DEFAULT_QOS}" =~ ^[0-2]$ ]] || ! [[ "${interval_val:-$DEFAULT_INTERVAL}" =~ ^[0-9]+$ ]] || \
   ! [[ "${limit_val:-$DEFAULT_LIMIT}" =~ ^[0-9]+$ ]]; then
    echo "Error: Uno o más parámetros son inválidos."
    exit 1
fi

# Asigna valores por defecto si el usuario no los introdujo.
qos_val=${qos_val:-$DEFAULT_QOS}
interval_val=${interval_val:-$DEFAULT_INTERVAL}
limit_val=${limit_val:-$DEFAULT_LIMIT}

# Define los archivos de salida para los logs.
output_dir="/home/azureuser"
mkdir -p "$output_dir"
command_logfile="${output_dir}/ipvs_pub_command_exp${exp_num}.txt"
metrics_logfile="${output_dir}/ipvs_pub_metrics_exp${exp_num}.txt"

# Construye el comando de emqtt-bench.
base_command="docker run --rm --network=host emqtt-bench pub"
params="-h ${host_ip} -p 1883 -c ${num_clients} -I ${interval_val} -L ${limit_val} -t bench/test -m \"mensaje_%i\" -q ${qos_val}"
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
    echo "  Intervalo (-I): $interval_val ms"
    echo "  Límite por Publicador (-L): $limit_val mensajes"
} > "$command_logfile"

echo ""
echo "Comando que se ejecutará:"
echo "${full_command} | tee ${metrics_logfile}"
echo ""
read -r -p "¿Lanzar el experimento? [S/n]: " confirm

if [[ "${confirm^^}" == "S" ]] || [[ -z "$confirm" ]]; then
    echo "Lanzando experimento de publicadores..."
    # Se usa eval para interpretar correctamente las comillas en el parámetro -m.
    eval "${full_command} | tee ${metrics_logfile}"
    echo "Experimento finalizado. Métricas guardadas en: ${metrics_logfile}"
else
    echo "Experimento cancelado."
fi

exit 0