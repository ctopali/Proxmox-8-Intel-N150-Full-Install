# pct for LXC or qm for VM 
# order es la jerarquía en que se ejecutara el contenedor con orden
# ascendente 1 es el primero, y el ultimo puede ser 99999 por ejemplo
# entre medio puedes destinar el numero entero que quieras para coordinar los servicios
# usaremos saltos de 10 en 10 por si en algun momento queremos incorporar
# algun servicio que deba arrancar entre los ya instalados.

#Columnas:
# qm/lxc XXX --on...  --startup #orden  ,#segundos de espera

# DNS primero (Adguard)
pct set 101 --onboot 1 --startup order=10

# Home Assistant VM
qm set 100 --onboot 1 --startup order=20,up=10

# Frigate
pct set 102 --onboot 1 --startup order=30,up=10

# Túnel Cloudflare (al final para que todos tengan su IP)
pct set 191 --onboot 1 --startup order=100
