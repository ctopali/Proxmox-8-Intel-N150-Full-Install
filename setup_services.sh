#!/usr/bin/env bash
set -e

#creamos el directorio de configuracion de los helper script si no existe
mkdir -p /usr/local/community-scripts/defaults

echo "--- 1. Descargando infraestructura de red ---"

curl -fsSL \
"https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main/infra.conf" \
-o /scripts/infra.conf

source /scripts/infra.conf

echo "Infraestructura cargada."
echo "Gateway : $GATEWAY"
echo "DNS     : $LOCAL_DNS"

echo "--- 2. Descargando archivo de configuración del Helper Script ---"

curl -fsSL \
"https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main/configs/adguard_test.vars" \
-o /usr/local/community-scripts/defaults/adguard_test.vars

echo
echo "Contenido de adguard_test.vars:"
echo "--------------------------------"

cat /usr/local/community-scripts/defaults/adguard_test.vars
