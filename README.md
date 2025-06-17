Resumen

El protocolo MQTT es el estándar predominante dentro del ámbito de Internet de las Cosas (IoT), pero su modelo de broker único presenta límites de escalabilidad críticos. Este trabajo evalúa empíricamente el uso de IP Virtual Server (IPVS) como equilibrador de carga a nivel de kernel para un clúster de brokers Mosquitto, comparando dos topologías fundamentales: una de equilibrio distribuido con múltiples puntos de entrada y otra de equilibrio centralizado con una visión global. Se desplegó una Prueba de Concepto (PoC) en Microsoft Azure y se ejecutaron pruebas de estrés con cargas de hasta 480 clientes simultáneos y 6.000 mensajes por ráfaga, bajo distintos niveles de calidad de servicio (QoS).

Los resultados revelaron un hallazgo clave y contraintuitivo. Bajo condiciones de sobrecarga extrema, la arquitectura centralizada, pese a distribuir las conexiones de forma casi perfecta, sufrió una pérdida de mensajes de aproximadamente un 25%. En contraste, la arquitectura distribuida, aunque menos precisa en su equilibrio, demostró ser más resiliente, manteniendo la pérdida en un 14%.

La principal contribución de esta investigación es la evidencia cuantitativa de que un equilibrio de carga óptimo en la capa de red/transporte no necesariamente garantiza la máxima fiabilidad en la capa de aplicación cuando el clúster está bajo saturación. El estudio concluye con pautas de diseño prácticas, derivadas de estos hallazgos, para la implementación de arquitecturas MQTT de alta disponibilidad.

Este repositorio contiene todos los scripts, configuraciones y artefactos utilizados para la Prueba de Concepto (PoC) descrita en el Trabajo de Fin de Máster. El documento completo de la tesis puede consultarse aquí: [Enlace a tu TFM si está disponible]
Palabras Clave

MQTT, IPVS, Equilibrio de Carga, Alta Disponibilidad, Escalabilidad, Mosquitto, Clúster, Pruebas de Rendimiento, IoT.
Estructura del Repositorio

El código está organizado en carpetas que se corresponden con los roles de las máquinas virtuales utilizadas en el entorno experimental.
Scripts para VM-BROKERS

    run_all_monitors.sh: Script principal para orquestar la monitorización. Lanza los dos scripts siguientes en segundo plano.
    monitor_brokers_csv.sh: Captura métricas de rendimiento de los contenedores (docker stats) a alta frecuencia y las guarda en formato CSV.
    monitor_brokers_txt.sh: Captura el estado de las conexiones de red (netstat) y los logs de los brokers a intervalos regulares.

Scripts para VM-IPVS (Balanceadores/Clientes)

    setup_ipvs.sh: Script de utilidad para limpiar y aplicar las reglas de IPVS antes de cada experimento.
    monitor_ipvs.sh: Script principal de monitorización que captura las estadísticas de ipvsadm en archivos de log y CSV.
    run_mqtt_pub.sh: Script interactivo para simplificar el lanzamiento de las pruebas de publicadores con emqtt-bench.
    run_mqtt_sub.sh: Script interactivo para simplificar el lanzamiento de las pruebas de suscriptores con emqtt-bench.

Configuraciones

    docker-compose.yml: Archivo de Docker Compose para desplegar el clúster de tres brokers Mosquitto con sus redes y límites de recursos.
    mosquitto.conf: Archivos de configuración para cada broker, incluyendo la implementación del bridge en topología de estrella.

Requisitos

    SO: Probado sobre Ubuntu 24.04 LTS.
    Contenerización: docker y docker-compose.
    Equilibrio de Carga: ipvsadm.
    Benchmarking: emqtt-bench (instrucciones para construir la imagen Docker incluidas).
    Shell: Bash para la ejecución de los scripts.
    Plataforma: La PoC fue desplegada en Microsoft Azure, pero la arquitectura es replicable en otras nubes o en entornos on-premise.
