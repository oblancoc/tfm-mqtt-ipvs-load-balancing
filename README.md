# Resumen

El protocolo **MQTT** es el estándar predominante dentro del ámbito de Internet de las Cosas (IoT), pero su modelo de _broker_ único presenta límites de escalabilidad críticos.  
Este trabajo evalúa empíricamente el uso de **IP Virtual Server (IPVS)** como equilibrador de carga a nivel de kernel para un clúster de brokers **Mosquitto**, comparando dos topologías fundamentales:

1. **Equilibrio distribuido** — múltiples puntos de entrada.  
2. **Equilibrio centralizado** — una única instancia con visión global.

Se desplegó una **Prueba de Concepto (PoC)** en Microsoft Azure y se ejecutaron pruebas de estrés con:

* **480** clientes simultáneos  
* **6 000** mensajes por ráfaga  
* Distintos niveles de **QoS** (1 y 2)

Los resultados revelaron un hallazgo clave y contraintuitivo:

* **Arquitectura centralizada** → ≈ 25 % de pérdida de mensajes bajo sobrecarga extrema, a pesar de equilibrar casi perfectamente las conexiones.  
* **Arquitectura distribuida** → pérdida limitada al **14 %**, mostrando mayor resiliencia aun con un reparto menos preciso.

> Un equilibrio óptimo en la capa de red/transporte (L4) **no siempre garantiza** la máxima fiabilidad en la capa de aplicación (L7) cuando el clúster está saturado.

El estudio concluye con **pautas de diseño prácticas** para arquitecturas MQTT de alta disponibilidad.

---

## Este repositorio

Contiene todos los **scripts, configuraciones y artefactos** empleados en la PoC.  

### Palabras clave

`MQTT`, `IPVS`, `Load-Balancing`, `High-Availability`, `Scalability`, `Mosquitto`, `Cluster`, `Performance-Testing`, `IoT`

---

## Estructura del repositorio

```text
.
├── brokers/                         # Contenedores Mosquitto
│   ├── broker1/
│   │   └── mosquitto.conf           # Configuración específica del Broker 1
│   ├── broker2/
│   │   └── mosquitto.conf           # Configuración específica del Broker 2
│   ├── broker3/                    
│   │   └── mosquitto.conf           # Configuración específica del Broker 3
│   ├── rules.v4                     # Reglas iptables persistentes de la VM-BROKERS
│   └── docker-compose.yml           # Orquesta los tres brokers y sus redes
│
├── ipvs1/                           # Config. completa de la VM-IPVS1
│   ├── ipvs_lc.rules                # Reglas del balanceador (Least-Connection / SNAT)
│   └── rules.v4                     # Reglas iptables para NAT y cadena FORWARD
│   
│   #  ➟  Las reglas de **IPVS2** son análogas; solo cambian las IP y
│   #     no incluyen las entradas exclusivas del escenario centralizado.
│
├── vm-brokers-scripts/              # Scripts para la VM-BROKERS
│   ├── run_all_monitors.sh
│   ├── monitor_brokers_csv.sh
│   └── monitor_brokers_txt.sh
│
├── vm-ipvs-scripts/                 # Scripts para las VM-IPVS
│   ├── setup_ipvs.sh
│   ├── monitor_ipvs.sh
│   ├── run_mqtt_pub.sh
│   └── run_mqtt_sub.sh
│
└── README.md


```

### Scripts para **VM-BROKERS**

| Script | Descripción |
|--------|-------------|
| `run_all_monitors.sh` | Orquestador principal; lanza ambos monitores en background. |
| `monitor_brokers_csv.sh` | Captura `docker stats` a alta frecuencia → CSV. |
| `monitor_brokers_txt.sh` | Registra `netstat` y logs de Mosquitto a intervalos regulares. |

### Scripts para **VM-IPVS** (balanceadores / clientes)

| Script | Descripción |
|--------|-------------|
| `setup_ipvs.sh`   | Limpia y aplica reglas IPVS antes de cada experimento. |
| `monitor_ipvs.sh` | Registra estadísticas `ipvsadm` (CSV + log). |
| `run_mqtt_pub.sh` | Lanzador interactivo de **publicadores** con `emqtt-bench`. |
| `run_mqtt_sub.sh` | Lanzador interactivo de **suscriptores** con `emqtt-bench`. |

### Configuraciones destacadas

* **`docker-compose.yml`** – despliega 3 brokers Mosquitto con límites de recursos.  
* **`mosquitto.conf`** – configuración por broker, incluye _bridge_ en topología estrella.

---

## Requisitos

| Componente | Versión mínima |
|------------|----------------|
| **SO**     | Ubuntu 24.04 LTS |
| **Contenedores** | `docker` + `docker-compose` |
| **Load Balancer** | `ipvsadm` |
| **Benchmark** | `emqtt-bench` (incluye Dockerfile) |
| **Shell**  | Bash |
| **Plataforma** | PoC desplegada en **Microsoft Azure**, pero replicable en otros entornos cloud u _on-premise_. |

---

### Cómo empezar

```bash
# 1) Clonar repositorio
git clone https://github.com/tu-usuario/tu-repo.git
cd tu-repo

# 2) Desplegar brokers (en VM-BROKERS)
cd brokers
docker-compose up -d

# 3) Configurar IPVS (en cada VM-IPVS)
cd ../vm-ipvs-scripts
sudo ./setup_ipvs.sh rules/lc_default.rules

# 4) Lanzar clientes de prueba
./run_mqtt_pub.sh
./run_mqtt_sub.sh
