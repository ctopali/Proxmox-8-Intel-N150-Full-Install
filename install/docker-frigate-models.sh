#!/usr/bin/env bash
set -e

source /scripts/infra.conf
source /scripts/lib.sh

echo "Creando archivo vars: ---"
#           APP       HOSTNAME  IP           CPU RAM DISK TUN GPU NEST
create_vars "docker-frigate-models" "docker-frigate-models" "debian" "13" "$DOCKER_IP" 1 512 20 yes no 0

echo "A continuación se ejecutará la instalación Helper-Script de"
echo "Docker, por favor, selecciona no compartir user data"
echo "y también selecciona en template 'App Defaults ...'."
echo
echo "Ejecutando Instalación de Docker: ---"
read -rp "Press Enter to continue..."
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/docker.sh)"


# App-specific defaults for Docker (docker)
# Generated on 2026-07-23T13:15:14Z

var_os=debian
var_version=13
var_unprivileged=1
var_cpu=2
var_ram=2048
var_disk=6
var_brg=vmbr0
var_net=192.168.1.19/24
var_gateway=192.168.1.254
var_ipv6_method=auto
var_ssh=no
var_apt_cacher=no
var_fuse=no
var_tun=no
var_gpu=no
var_nesting=1
var_keyctl=1
var_mknod=0
var_protection=no
var_timezone=America/Santiago
var_tags=
var_verbose=yes
var_hostname=docker-frigate-models
var_template_storage=local
var_container_storage=local-lvm
