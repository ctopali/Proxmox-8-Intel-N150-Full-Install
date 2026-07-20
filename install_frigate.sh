echo "Creación del archivo frigate.vars..."
create_vars "Frigate" "frigate" "debian" "13" "$FRIGATE_IP" 4 4096 32 yes yes 1

echo "Instalación del servicio Frigate:"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/frigate.sh)"

# Modificación del archivo yaml de configuración de Frigate:
