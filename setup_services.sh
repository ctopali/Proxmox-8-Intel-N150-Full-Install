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
echo "Bridge        : $BRIDGE"
echo "Gateway       : $GATEWAY"
echo "DNS (Adguard) : $LOCAL_DNS"
echo "Netmask       : $NETMASK"
echo "TimeZone      : $TIMEZONE"

echo "--- 2. Crear archivos de vars para Helper-Scripts: ---"
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
create_vars() {
    local APP="$1"
    local HOSTNAME="$2"
    local OS="$3"
    local OSV="$4"
    local IP="$5"
    local CPU="$6"
    local RAM="$7"
    local DISK="$8"
    local TUN="$9"
    local GPU="$10"
    local NEST="$11"

    cat >"/usr/local/community-scripts/defaults/${HOSTNAME}.vars" <<EOF
# App-specific defaults for $APP ($HOSTNAME)
# Generated on $DATE

var_os=$OS
var_version=$OSV
var_unprivileged=1
var_cpu=$CPU
var_ram=$RAM
var_disk=$DISK
var_brg=$BRIDGE
var_net=$IP/$NETMASK
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
var_verbose=yes
var_hostname=$HOSTNAME
var_template_storage=local
var_container_storage=local-lvm
EOF

echo
echo "Contenido de adguard_test.vars:"
echo "--------------------------------"
cat /usr/local/community-scripts/defaults/${HOSTNAME}.vars
rm /usr/local/community-scripts/defaults/${HOSTNAME}.vars
}

echo "--- 2.1. Adguard test ---"
Encabezados de create_vars:
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
create_vars "AdGuard" "adguard_test" "debian" "13" "$ADGUARD_IP_TEST" 1 512 2 yes no 0

echo "--- 2.2. Cloudflared ---"
# Instalacion de Debian 13 limpia:
# Chatgpt cambia esta línea por una instalación debian 13 usando el bash con este formato: create_vars "Cloudflared" "cloudflared" "debian" "13" "$CLOUDFLARED_IP" 1 512 4 yes no 0
# Add cloudflare gpg key
mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null

# Add this repo to your apt repositories
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list

# install cloudflared
apt-get update && apt-get install cloudflared -y

# Entramos a Cloudflare -> Networks -> Connectors

#echo "--- 2.1 Creando los archivos de configuracion.vars ---"
#create_vars "AdGuard" "adguard" "debian" "13" "$ADGUARD_IP" 1 512 2 yes no 0
#create_vars "Frigate" "frigate" "debian" "13" "$FRIGATE_IP" 4 4096 32 yes yes 1
#create_vars "Cloudflared" "cloudflared" "debian" "13" "$CLOUDFLARED_IP" 1 512 4 yes no 0
