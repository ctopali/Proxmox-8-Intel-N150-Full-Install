#!/usr/bin/env bash
set -e

echo "1. Copiamos los scripts que se utilizaran:"

curl -fsSL \
"https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main/setup_sensors.sh" \
-o /scripts/setup_sensors.sh
echo "1.1. Script de sensors... CHECK"

curl -fsSL \
"https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main/setup_services.sh" \
-o /scripts/setup_services.sh
echo "1.2. Script de services... CHECK"

echo "2. Ejecucuion de Scripts y comandos bash:"
echo "2.1 Ejecutando setup_sesors.sh:"
bash /scripts/setup_sensors.sh
bash /scripts/setup_services.sh
