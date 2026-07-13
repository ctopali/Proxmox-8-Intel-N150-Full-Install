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

echo "--- 2. Crear archivos de vars para Helper-Scripts: ---"

create_vars() {
    local APP="$1"
    local HOSTNAME="$2"
    local IP="$3"
    local CPU="$4"
    local RAM="$5"
    local DISK="$6"
    local TUN="$7"
    local GPU="$8"
    local NEST="$9"

    cat >"/usr/local/community-scripts/defaults/${HOSTNAME}.vars" <<EOF
# App-specific defaults for $APP ($HOSTNAME)
# Generated on $DATE

var_os=$OS
var_version=$OSV
var_unprivileged=1
var_cpu=$CPU
var_ram=$RAM
var_disk=$DISK
var_brg=vmbr0
var_net=$IP/24
var_gateway=$GATEWAY
var_ipv6_method=auto
var_ssh=no
var_apt_cacher=no
var_fuse=no
var_tun=$TUN
var_gpu=$GPU
var_nesting=$NEST
var_keyctl=1
var_mknod=0
var_protection=no
var_timezone=$TIMEZONE
var_tags=
var_verbose=no
var_hostname=$HOSTNAME
var_template_storage=local
var_container_storage=local-lvm
EOF
}

echo "--- 2.1. Adguard test ---"
#Encabezados de create_vars:
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
create_vars "AdGuard" "adguard" "$ADGUARD_IP" 1 512 2 yes no 0

echo "--- 2.1 Creando los archivos de configuracion.vars ---"
#create_vars "AdGuard" "adguard" "$ADGUARD_IP" 1 512 2 yes no 0
#create_vars "Frigate" "frigate" "$FRIGATE_IP" 4 4096 32 yes yes 1
#create_vars "Cloudflared" "cloudflared" "$CLOUDFLARED_IP" 1 512 4 yes no 0

echo
echo "Contenido de adguard_test.vars:"
echo "--------------------------------"

cat /usr/local/community-scripts/defaults/adguard_test.vars
#lo borro y verifico que no existe, solo me interesa crear bien el archivo en este minuto
rm /usr/local/community-scripts/defaults/adguard_test.vars
cat /usr/local/community-scripts/defaults/adguard_test.vars
