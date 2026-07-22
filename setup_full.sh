#!/usr/bin/env bash
set -e

SETUP_VERSION="0.1b"

SCRIPTS_DIR="/scripts"
REPO_URL="https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main"

mkdir -p "$SCRIPTS_DIR"

get_remote_setup_version() {
    curl -fsSL "$REPO_URL/setup_full.sh" \
    | grep '^SETUP_VERSION=' \
    | sed -E 's/.*="?([^"]+)"?.*/\1/'
}

LOCAL_SETUP_VERSION="$SETUP_VERSION"
REMOTE_SETUP_VERSION=$(get_remote_setup_version)

update_project() {
    local TMP_LIST
    TMP_LIST=$(mktemp)
    echo "Descargando lista de archivos..."
    curl -fsSL "$REPO_URL/files.list" -o "$TMP_LIST"
    while IFS= read -r FILE; do
        [[ -z "$FILE" || "$FILE" =~ ^# ]] && continue
        echo "Descargando $FILE..."
        mkdir -p "$SCRIPTS_DIR/$(dirname "$FILE")"
        curl -fsSL \
            "$REPO_URL/$FILE" \
            -o "$SCRIPTS_DIR/$FILE"
    done < "$TMP_LIST"
    rm -f "$TMP_LIST"
    echo
    echo "Proyecto actualizado correctamente."
}

if [[ "$LOCAL_SETUP_VERSION" != "$REMOTE_SETUP_VERSION" ]]; then
    echo
    read -rp "Hay una nueva versión disponible ($REMOTE_SETUP_VERSION). ¿Actualizar el proyecto completo? [y/N]: " RESP
    if [[ "$RESP" =~ ^([Yy]|[Yy][Ee][Ss]|[Ss][Ii]|[Ss][Íí])$ ]]; then
        update_project
        echo
        echo "Reiniciando instalador..."
        exec "$SCRIPTS_DIR/setup_full.sh"
    fi
fi

echo "--- Cargando configuración ---"

source /scripts/infra.conf
source /scripts/lib.sh

check_infra

#######################################################
# Agregar las opciones aquí de scripts automatizados: #
#######################################################

SCRIPTS[1]="setup/setup_sensors.sh|Instalar sensores y drivers IT87"
SCRIPTS[2]="setup/setup_disks.sh|Instala y Modifica Disco ZFS 'frigate_mirror'"
SCRIPTS[3]="install/install_haos.sh|Instalar Home Assistant OS (VM)"
SCRIPTS[4]="install/install_adguard.sh|Instalar AdGuard Home (LXC)"
SCRIPTS[5]="install/install_cloudflared.sh|Instalar Cloudflared (LXC)"
SCRIPTS[6]="install/install_frigate.sh|Instalar Frigate (LXC)"
SCRIPTS[9]="setup/setup_startup.sh|Ordena el orden de Inicio de LXC y VMs"

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
