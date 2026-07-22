#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/lib.sh

echo "Creando archivo vars: ---"
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
echo "Creación del archivo frigate.vars..."
create_vars "Frigate" "frigate" "debian" "12" "$FRIGATE_IP" 4 4096 32 yes yes 1

echo "A continuación se ejecutará la instalación Helper-Script de"
echo "Frigate, por favor, selecciona no compartir user data"
echo "y también selecciona en template 'App Defaults ...'."
echo
echo "Instalación del servicio Frigate:"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/frigate.sh)"

CTID=get_ctid_by_hostname frigate

pct stop $CTID
pct set $CTID -mp0 /mnt/frigate,mp=/media/frigate
pct start $CTID
pct exec $CTID ls -lah /media/frigate

if ! touch /media/frigate/recordings/prueba then
  
# Modificación del archivo yaml de configuración de Frigate:
cat pct $CTID config.yaml < EOF

EOF
