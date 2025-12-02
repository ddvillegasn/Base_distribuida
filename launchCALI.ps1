# Script para lanzar el nodo CALI y su réplica.

# Iniciar nodo principal
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Cali.db --http-addr=10.1.1.4:8080 --config-file=sharding-distributed.toml --shard=Cali"

# Iniciar réplica
# Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Cali-r.db --http-addr=127.0.0.44:8080 --config-file=sharding.toml --shard=Cali --replica"

Write-Host "Se ha iniciado el nodo CALI y su réplica."
Write-Host "1 nodo principal + 1 replica = 2 procesos en total"