#!/usr/bin/env bash
set -e

inst-script() {
    local SCRIPT="$1"
    local PREGUNTA="$2"

    echo
    read -rp "$PREGUNTA [y/N]: " RESP

    case "${RESP,,}" in
        y|yes|s|si|sí)
            echo "Continuando..."

            if [[ -f "/scripts/$SCRIPT" ]]; then
                echo "$SCRIPT ya está descargado."
            else
                echo "Descargando $SCRIPT..."
                curl -fsSL \
                    "https://raw.githubusercontent.com/ctopali/Proxmox-8-Intel-N150-Full-Install/refs/heads/main/$SCRIPT" \
                    -o "/scripts/$SCRIPT"
            fi

            echo "Ejecutando $SCRIPT..."
            bash "/scripts/$SCRIPT"
            ;;

        *)
            echo "Se omitió $SCRIPT."
            return 0
            ;;
    esac
}

check_infra() {
    local required_vars=(
        BRIDGE
        GATEWAY
        LOCAL_DNS
        NETMASK
        TIMEZONE
    )

    for var in "${required_vars[@]}"; do
        [[ -n "${!var:-}" ]] || {
            echo "ERROR: setup_services.sh requiere que primero se haga:"
            echo "  source /scripts/infra.conf"
            echo "Variable faltante: $var"
            return 1
        }
    done

    echo "Infraestructura cargada."
    echo "Bridge        : $BRIDGE"
    echo "Gateway       : $GATEWAY"
    echo "DNS (AdGuard) : $LOCAL_DNS"
    echo "Netmask       : $NETMASK"
    echo "TimeZone      : $TIMEZONE"
}

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
    local GPU="${10}"
    local NEST="${11}"

    # Validación de parámetros obligatorios
    local PARAMS=(
        APP
        HOSTNAME
        OS
        OSV
        IP
        CPU
        RAM
        DISK
        TUN
        GPU
        NEST
    )

    for param in "${PARAMS[@]}"; do
        if [[ -z "${!param}" ]]; then
            echo "ERROR: Falta el parámetro obligatorio: $param"
            echo
            echo "Uso:"
            echo "create_vars APP HOSTNAME OS OS_VERSION IP CPU RAM DISK TUN GPU NEST"
            return 1
        fi
    done
    
    local DATE
    DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local VARS_FILE="/usr/local/community-scripts/defaults/${HOSTNAME}.vars"

    #creamos el directorio de configuracion de los helper script si no existe
    mkdir -p /usr/local/community-scripts/defaults

    cat >"$VARS_FILE" <<EOF
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
echo "Archivo creado: $VARS_FILE"
}

# Obtiene CTID por hostname del contenedor LXC
# Uso:
# CTID=$(get_ctid_by_hostname "adguard")

get_ctid_by_hostname() {

    local HOSTNAME="$1"

    if [[ -z "$HOSTNAME" ]]; then
        echo "ERROR: Debe indicar un hostname."
        return 1
    fi

    local CTID

    CTID=$(pct list | awk -v host="$HOSTNAME" 'NR>1 && $3==host {print $1}')

    if [[ -z "$CTID" ]]; then
        echo "ERROR: No se encontró el contenedor: $HOSTNAME" >&2
        return 1
    fi

    echo "$CTID"
}

create_lxc_from_vars() {

    local CTID="$1"
    local VARS="$2"

    source "$VARS"

    echo "Buscando template Debian 13..."

    TEMPLATE=$(find /var/lib/vz/template/cache \
        -maxdepth 1 \
        -type f \
        -name "debian-13-standard*.tar.zst" \
        | sort -V \
        | tail -n1)


    if [[ -z "$TEMPLATE" ]]; then
        echo "ERROR: No existe un template Debian 13."
        echo
        echo "Templates disponibles:"
        ls -lh /var/lib/vz/template/cache
        exit 1
    fi


    TEMPLATE_NAME=$(basename "$TEMPLATE")

    echo "Template seleccionado:"
    echo "$TEMPLATE_NAME"


    pct create "$CTID" \
        "local:vztmpl/$TEMPLATE_NAME" \
        --hostname "$var_hostname" \
        --cores "$var_cpu" \
        --memory "$var_ram" \
        --rootfs "$var_container_storage:$var_disk" \
        --net0 "name=eth0,bridge=$var_brg,ip=$var_net,gw=$var_gateway" \
        --unprivileged "$var_unprivileged" \
        --features "nesting=$var_nesting,keyctl=$var_keyctl"

}
