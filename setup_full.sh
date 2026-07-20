#!/usr/bin/env bash
set -e

SCRIPTS_DIR="/scripts"
REPO_URL="https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main"

mkdir -p "$SCRIPTS_DIR"

download_if_needed() {

    local FILE="$1"
    local VERSION_VAR="$2"
    local VERSION_NAME="$3"

    local LOCAL_FILE="$SCRIPTS_DIR/$FILE"

    # Descargar siempre si no existe
    if [[ ! -f "$LOCAL_FILE" ]]; then
        echo "$FILE no existe. Descargando..."
        curl -fsSL "$REPO_URL/$FILE" -o "$LOCAL_FILE"
        return
    fi


    # Obtener versión local
    LOCAL_VERSION=$(grep "^$VERSION_VAR=" "$LOCAL_FILE" | cut -d'"' -f2)


    # Obtener versión remota temporal
    REMOTE_TMP=$(mktemp)

    curl -fsSL \
        "$REPO_URL/$FILE" \
        -o "$REMOTE_TMP"


    REMOTE_VERSION=$(grep "^$VERSION_VAR=" "$REMOTE_TMP" | cut -d'"' -f2)


    if [[ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]]; then

        echo "Actualizando $FILE"
        echo "Versión local : $LOCAL_VERSION"
        echo "Versión nueva : $REMOTE_VERSION"

        cp "$REMOTE_TMP" "$LOCAL_FILE"

    else
        echo "$FILE actualizado ($LOCAL_VERSION)"
    fi


    rm -f "$REMOTE_TMP"
}


echo "--- Verificando archivos base ---"


download_if_needed \
    "infra.conf" \
    "INFRA_VERSION" \
    "Infraestructura"


download_if_needed \
    "setup_services.sh" \
    "SERVICES_VERSION" \
    "Servicios"


echo "--- Cargando configuración ---"

source /scripts/infra.conf
source /scripts/setup_services.sh

check_infra

SCRIPTS[1]="setup_sensors.sh|Instalar sensores y drivers IT87"
SCRIPTS[2]="install_haos.sh|Instalar Home Assistant OS (VM)"
SCRIPTS[3]="install_adguard.sh|Instalar AdGuard Home (LXC)"
SCRIPTS[4]="install_cloudflared.sh|Instalar Cloudflared (LXC)"
SCRIPTS[5]="install_frigate.sh|Instalar Frigate (LXC)"

while true; do

    echo
    echo "======================================"
    echo "       INSTALADOR PROXMOX"
    echo "======================================"

    for i in $(printf "%s\n" "${!SCRIPTS[@]}" | sort -n); do
        
        IFS="|" read -r SCRIPT DESC <<< "${SCRIPTS[$i]}"

        echo "$i) $DESC"
    done

    MAX_OPTION=$(printf "%s\n" "${!SCRIPTS[@]}" | sort -n | tail -1)

    echo
    echo "0) Salir"
    echo

    read -rp "Seleccione una opción [0-$MAX_OPTION]: " OPTION

    case "$OPTION" in

        0)
            echo "Saliendo..."
            exit 0
            ;;

        *)
            if [[ -n "${SCRIPTS[$OPTION]}" ]]; then

                IFS="|" read -r SCRIPT DESC <<< "${SCRIPTS[$OPTION]}"

                echo
                echo "Ejecutando:"
                echo "$DESC"
                echo

                inst-script \
                    "$SCRIPT" \
                    "¿Desea ejecutar: $DESC?"

            else
                echo "Opción inválida."
            fi
            ;;

    esac

done
