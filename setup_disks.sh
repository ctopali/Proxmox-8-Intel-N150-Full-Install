#!/usr/bin/env bash
set -euo pipefail

POOL="frigate_mirror"
MOUNT="/mnt/frigate"

echo "========================================"
echo " Revisando discos"
echo "========================================"

command -v zpool >/dev/null || {
    echo "ERROR: Las herramientas ZFS no están instaladas."
    exit 1
}

command -v zfs >/dev/null || {
    echo "ERROR: zfs no está instalado."
    exit 1
}

lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT

echo
echo "========================================"
echo " Importando todas las pools disponibles"
echo "========================================"

zpool import -a || true

echo
echo "========================================"
echo " Pools activos:"
echo "========================================"

zpool list

echo
echo "========================================"
echo " Pools estado:"
echo "========================================"

zpool status

echo

if ! zpool list -H -o name | grep -Fxq "${POOL}"; then
    echo "ERROR:"
    echo "No existe el pool ${POOL}"
    echo "Debes crear el zfs 'frigate_mirror' primero:"
    echo "Navega: pve -> Diks -> ZFS -> Create: ZFS"
    echo "Name: frigate_mirror; RAID Level: Mirror"
    echo "Compression: lz4; ashift: 12"
    echo "y seleccionar dos discos y click en 'Create'"
    exit 1
fi

echo
echo "========================================"
echo " Configurando propiedades frigate_mirror"
echo "========================================"

zfs set compression=lz4 "${POOL}"
zfs set atime=off "${POOL}"
zfs set xattr=sa "${POOL}"
zfs set acltype=posixacl "${POOL}"
zfs set relatime=on "${POOL}"
zfs set aclinherit=passthrough "${POOL}"
zfs set dnodesize=auto "${POOL}"

echo
echo "========================================"
echo " Creando datasets"
echo "========================================"

zfs set mountpoint="${MOUNT}" "${POOL}"

create_dataset() {
    local DATASET="$1"

    if ! zfs list -H -o name "${POOL}/${DATASET}" >/dev/null 2>&1; then
        echo "Creando dataset ${DATASET}"
        zfs create "${POOL}/${DATASET}"
    else
        echo "✓ Dataset ${DATASET} ya existe"
    fi
}

create_dataset recordings
create_dataset clips
create_dataset snapshots
create_dataset exports

# Recordsize de 1 MiB recomendado para grabaciones secuenciales
if zfs list -H -o name "${POOL}/recordings" >/dev/null 2>&1; then
    zfs set recordsize=1M "${POOL}/recordings"
fi

echo
echo "========================================"
echo " Permisos"
echo "========================================"

# Aqui podemos configurar un usuario para frigate (si es que queremos agregar alguno aparte del root) y pueda escribir en el pool
FRIGATE_UID=0
FRIGATE_GID=0

if [ -d "${MOUNT}" ]; then
    chown -R "${FRIGATE_UID}:${FRIGATE_GID}" "${MOUNT}"
    chmod -R 755 "${MOUNT}"
fi
echo
echo "========================================"
echo " Información Post-Modificaciones"
echo "========================================"

echo "Datasets creados:"
zfs list -r "${POOL}"

echo
echo "Punto de montaje:"
df -h "${MOUNT}"

echo
echo "Propiedades del pool:"
zfs get \
    compression,atime,relatime,xattr,acltype,aclinherit,dnodesize,mountpoint \
    "${POOL}"

echo
echo "Propiedades del dataset recordings:"
zfs get recordsize "${POOL}/recordings"

echo
echo "========================================"
echo " Finalizado"
echo "========================================"
