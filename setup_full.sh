#!/usr/bin/env bash
set -e

#############################################
# Configuración
#############################################

SCRIPTS_DIR="/scripts"
REPO_URL="https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main"

MANIFEST_LOCAL="$SCRIPTS_DIR/manifest.list"
MANIFEST_REMOTE="$(mktemp)"

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || echo "")"

mkdir -p "$SCRIPTS_DIR"

#############################################
# Funciones
#############################################

download_manifest() {

    curl -fsSL \
        "$REPO_URL/manifest.list" \
        -o "$1"

}

get_manifest_version() {

    grep '^META|SETUP_VERSION|' "$1" | cut -d'|' -f3

}

update_project() {

    echo
    echo "Actualizando proyecto..."
    echo

    echo "Descargando setup_full.sh..."
    curl -fsSL \
        "$REPO_URL/setup_full.sh" \
        -o "$SCRIPTS_DIR/setup_full.sh"

    echo "Descargando manifest.list..."
    download_manifest "$MANIFEST_LOCAL"

    while IFS='|' read -r TYPE FILE MENU DESC; do

        [[ -z "$TYPE" || "$TYPE" =~ ^# ]] && continue
        [[ "$TYPE" == "META" ]] && continue

        echo "Descargando $FILE..."

        mkdir -p "$SCRIPTS_DIR/$(dirname "$FILE")"

        if ! curl -fsSL \
            "$REPO_URL/$FILE" \
            -o "$SCRIPTS_DIR/$FILE"; then

            echo
            echo "ERROR: No fue posible descargar '$FILE'."
            echo "El proyecto quedó incompleto."
            echo
            echo "¡¡IMPORTANTE!!
            echo "Hable con el admin del script y pidale que"
            echo "Corrija el archivo manifest.list del repositorio."
            echo "Una vez resuelto vuelva a ejecutar el instalador."

            rm -f "$MANIFEST_LOCAL"

            exit 1

        fi

    done < "$MANIFEST_LOCAL"

    echo
    echo "Proyecto actualizado."

}

ensure_project() {

    if [[ ! -f "$MANIFEST_LOCAL" ]]; then

        echo "Primera ejecución."

        update_project

        echo
        echo "Reiniciando instalador..."
        exec bash "$SCRIPTS_DIR/setup_full.sh"

    fi

}

check_updates() {

    download_manifest "$MANIFEST_REMOTE"

    LOCAL_VERSION=$(get_manifest_version "$MANIFEST_LOCAL")
    REMOTE_VERSION=$(get_manifest_version "$MANIFEST_REMOTE")

    rm -f "$MANIFEST_REMOTE"

    [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]] && return

    echo
    read -rp "Hay una nueva versión disponible ($REMOTE_VERSION). ¿Actualizar el proyecto? [y/N]: " RESP

    if [[ "$RESP" =~ ^([Yy]|[Yy][Ee][Ss]|[Ss][Ii]|[Ss][Íí])$ ]]; then

        update_project

        echo
        echo "Reiniciando instalador..."

        exec bash "$SCRIPTS_DIR/setup_full.sh"

    fi

}

run_local_setup() {

    if [[ "$SCRIPT_PATH" != "$SCRIPTS_DIR/setup_full.sh" ]] && [[ -f "$SCRIPTS_DIR/setup_full.sh" ]]; then

        echo
        echo "Ejecutando instalador local..."
        exec bash "$SCRIPTS_DIR/setup_full.sh"

    fi

}

load_menu() {

    declare -gA SCRIPTS

    while IFS='|' read -r TYPE FILE MENU DESC; do

        [[ "$TYPE" != "MENU" ]] && continue

        SCRIPTS["$MENU"]="$FILE|$DESC"

    done < "$MANIFEST_LOCAL"

}

menu_loop() {

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

}

#############################################
# Main
#############################################

ensure_project

check_updates

run_local_setup

echo "--- Cargando configuración ---"

source "$SCRIPTS_DIR/infra.conf"
source "$SCRIPTS_DIR/lib.sh"

check_infra

load_menu

menu_loop
