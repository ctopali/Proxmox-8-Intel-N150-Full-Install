#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/setup_services.sh
#source /scripts/lib.sh

inst-script() {
    local SCRIPT="$1"
    local PREGUNTA="$2"

    echo
    read -rp "$PREGUNTA [y/N]: " RESP

    case "${RESP,,}" in
        y|yes|s|si|sí)
            echo "Continuando..."

            if [[ -f "/scripts/$SCRIPT" ]]; then
                echo "$SCRIPT ya está descargado."
            else
                echo "Descargando $SCRIPT..."
                curl -fsSL \
                    "https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main/$SCRIPT" \
                    -o "/scripts/$SCRIPT"
            fi

            echo "Ejecutando $SCRIPT..."
            bash "/scripts/$SCRIPT"
            ;;

        *)
            echo "Se omitió $SCRIPT."
            return 0
            ;;
    esac
}

echo "1. Instalar sensores y drivers de la MB IT87 (si aplica):"
inst-script \
    "setup_sensors.sh" \
    "¿Desea instalar los controladores y sensores de la Tarjeta Madre IT87?"

echo "2. Instalar Home Assistant (VM):"
inst-script \
    "setup_sensors.sh" \
    "¿Desea instalar los controladores y sensores de la Tarjeta Madre IT87?"

curl -fsSL \
"https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main/setup_startup.sh" \
-o /scripts/setup_startup.sh
echo "1.3. Script de setup_startup... CHECK"

echo "2. Ejecucuion de Scripts y comandos bash:"
echo "2.1 Ejecutando setup_sesors.sh:"
bash /scripts/setup_sensors.sh

echo "2.2 Ejecutando setup_services.sh:"
bash /scripts/setup_services.sh
