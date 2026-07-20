#!/usr/bin/env bash
set -e

# Script de automatización de sensores para Proxmox (Chip ITE IT8613E)
# Autor: Gemini para Camilo
# Fecha: Marzo 2026

set -e

echo "--- 1. Actualizando Repositorios e Instalando Dependencias ---"
apt update
apt install -y git build-essential dkms pve-headers lm-sensors fancontrol

echo "--- 2. Configurando GRUB (acpi_enforce_resources=lax) ---"
# Verifica si el parámetro ya existe para no duplicarlo
if ! grep -q "acpi_enforce_resources=lax" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="acpi_enforce_resources=lax /' /etc/default/grub
    update-grub
    echo "Grub actualizado. Se requiere reinicio al finalizar."
else
    echo "Grub ya estaba configurado."
fi

echo "--- 3. Instalando Driver IT87 de la Comunidad (Mejor soporte para IT8613E) ---"
cd /tmp
rm -rf it87
git clone https://github.com/frankcrawford/it87.git
cd it87
make
# Instalamos con DKMS para que el driver sobreviva a actualizaciones de kernel de Proxmox
make dkms

echo "--- 4. Configurando Persistencia de Módulos ---"
# Asegurar que it87 cargue con el ID forzado que nos funcionó
echo "it87" > /etc/modules-load.d/it87.conf
echo "options it87 force_id=0x8628" > /etc/modprobe.d/it87.conf

echo "--- 5. Cargando Módulo Actual ---"
modprobe it87 force_id=0x8628 || echo "Error cargando modprobe, es normal si no has reiniciado con el nuevo GRUB."

echo "-------------------------------------------------------"
echo "¡LISTO! Pasos finales sugeridos:"
echo "1. Reinicia el servidor: 'reboot'"
echo "2. Al volver, ejecuta 'sensors' para verificar."
echo "3. Luego ejecuta 'pwmconfig' para configurar tus curvas de ventilación."
echo "-------------------------------------------------------"
