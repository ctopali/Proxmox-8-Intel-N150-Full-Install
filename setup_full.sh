#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/setup_services.sh
#source /scripts/lib.sh

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
