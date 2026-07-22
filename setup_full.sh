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
    echo "Descargando setup_full.sh..."
    curl -fsSL \
        "$REPO_URL/setup_full.sh" \
        -o "$SCRIPTS_DIR/setup_full.sh"
    echo "Descargando lista de archivos..."
    curl -fsSL "$REPO_URL/manifest.list" -o "$TMP_LIST"
    while IFS='|' read -r TYPE FILE MENU DESC; do
        [[ -z "$TYPE" || "$TYPE" =~ ^# ]] && continue
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

if [[ ! -f "$SCRIPTS_DIR/infra.conf" || ! -f "$SCRIPTS_DIR/lib.sh" ]]; then
    echo "Primera ejecución. Descargando archivos del proyecto..."
    update_project
fi

if [[ "$LOCAL_SETUP_VERSION" != "$REMOTE_SETUP_VERSION" ]]; then
    echo
    read -rp "Hay una nueva versión disponible ($REMOTE_SETUP_VERSION). ¿Actualizar el proyecto completo? [y/N]: " RESP
    if [[ "$RESP" =~ ^([Yy]|[Yy][Ee][Ss]|[Ss][Ii]|[Ss][Íí])$ ]]; then
        update_project
        echo
        echo "Reiniciando instalador..."
        exec bash "$SCRIPTS_DIR/setup_full.sh"
    fi
fi

echo "--- Cargando configuración ---"

source "$SCRIPTS_DIR/infra.conf"
source "$SCRIPTS_DIR/lib.sh"

check_infra

declare -A SCRIPTS

while IFS='|' read -r TYPE FILE MENU DESC; do

    [[ -z "$TYPE" || "$TYPE" =~ ^# ]] && continue
    [[ "$TYPE" != "MENU" ]] && continue

    SCRIPTS["$MENU"]="$FILE|$DESC"

done < "$SCRIPTS_DIR/project.list"

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
